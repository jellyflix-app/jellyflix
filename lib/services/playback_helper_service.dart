import 'package:jellyflix/models/bitrates.dart';
import 'package:jellyflix/services/api_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:tentacle/tentacle.dart';

class PlaybackHelperService {
  PlaybackInfoResponse item;
  Map<int, String> bitrateMap = BitRates().map;

  late List<MediaStream> audioStreams;
  late List<MediaStream> subtitles;
  late Map<MediaStream, int?> mappedSubtitles;
  late Map<MediaStream, int?> mappedAudioStreams;
  late final Player _player;
  late final ApiService _apiService;

  late MediaStream audioStream;
  late MediaStream subtitle;
  late int bitrate;
  late bool isSubtitleEnabled;
  late bool isTranscoding;

  PlaybackHelperService(
      {required this.item, required player, required apiService}) {
    initAudioList();
    initSubtitleList();
    audioStream = getDefaultAudio();
    subtitle = getDefaultSubtitle();
    bitrate = getDefaultBitrate();
    isSubtitleEnabled = subtitle.index != -1;
    isTranscoding = item.mediaSources![0].transcodingUrl != null;
    _player = player;
    _apiService = apiService;
  }

  Map<int, String> getBitrateMap() {
    // add orignal bitrate at the beginning
    bitrateMap[item.mediaSources![0].bitrate ?? 0] =
        "Original ${item.mediaSources![0].bitrate! ~/ 1000000} Mb/s";
    // add original bitrate at the beginning and sort the rest descending
    bitrateMap = Map.fromEntries(
      bitrateMap.entries.toList()..sort((e1, e2) => e2.key.compareTo(e1.key)),
    );
    // remove bitrates that are higher than the original
    bitrateMap
        .removeWhere((key, value) => key > item.mediaSources![0].bitrate!);

    return bitrateMap;
  }

  int getDefaultBitrate() {
    return item.mediaSources![0].bitrate ?? 0;
  }

  void initSubtitleList() {
    MediaStream noneMediaStream = MediaStream(
      (b) {
        b.displayTitle = "None";
        b.index = -1;
        b.isExternal = false;
      },
    );
    // values are the index of the subtitle stream, if they are embedded
    subtitles = [
      noneMediaStream,
      ...item.mediaSources![0].mediaStreams!
          .where((element) => element.type == MediaStreamType.subtitle)
          .toList()
    ];
    int index = 1;
    // map the subtitle streams to the index
    Map<MediaStream, int?> subtitleMap = {};
    for (var stream in subtitles) {
      if (stream.isExternal!) {
        subtitleMap.addAll({stream: null});
      } else {
        subtitleMap.addAll({stream: index});
        index++;
      }
    }
    mappedSubtitles = subtitleMap;
  }

  void initAudioList() {
    // values are the index of the embedded audio stream
    audioStreams = item.mediaSources![0].mediaStreams!
        .where((element) => element.type == MediaStreamType.audio)
        .toList();
    int index = 2;
    // map the audio streams to the index
    Map<MediaStream, int?> audioMap = {};
    for (var stream in audioStreams) {
      audioMap.addAll({stream: index});
      index++;
    }

    mappedAudioStreams = audioMap;
  }

  MediaStream getDefaultAudio() {
    int index = item.mediaSources![0].defaultAudioStreamIndex ?? -1;
    return audioStreams.firstWhere((element) => element.index == index);
  }

  MediaStream getDefaultSubtitle() {
    int index = item.mediaSources![0].defaultSubtitleStreamIndex ?? -1;
    return subtitles.firstWhere((element) => element.index == index);
  }

  Future<void> setSubtitle(MediaStream mediaStream) async {
    mediaStream =
        subtitles.firstWhere((element) => element.index == mediaStream.index);
    if (mediaStream.deliveryMethod == SubtitleDeliveryMethod.external_) {
      // external subtitles
      SubtitleTrack externalSubtitle = await _apiService.getExternalSubtitle(
          deliveryUrl: mediaStream.deliveryUrl!);
      _player.setSubtitleTrack(externalSubtitle);
      isSubtitleEnabled = true;
      subtitle = mediaStream;
    } else if (isTranscoding &&
        mediaStream.index != subtitle.index &&
        subtitle.deliveryMethod == SubtitleDeliveryMethod.embed) {
      await requestNewStream(subtitleIndex: mediaStream.index);
    } else {
      if (mediaStream.index == -1) {
        // no subtitles is track with index 1
        _player.setSubtitleTrack(_player.state.tracks.subtitle[1]);
        isSubtitleEnabled = false;
      } else {
        int index = mappedSubtitles[mediaStream]!;
        _player.setSubtitleTrack(_player.state.tracks.subtitle[index]);
        isSubtitleEnabled = true;
        subtitle = mediaStream;
      }
    }
  }

  Future<void> disableSubtitle() async {
    _player.setSubtitleTrack(_player.state.tracks.subtitle[1]);
    isSubtitleEnabled = false;
  }

  Future<void> enableSubtitle() async {
    if (subtitle.index == -1) {
      // index 0 is no subtitle
      await setSubtitle(subtitles[1]);
    } else {
      await setSubtitle(subtitle);
    }
  }

  Future<void> setBitrate(int maxStreamingBitrate) async {
    await requestNewStream(
      maxStreamingBitrate: maxStreamingBitrate,
    );
  }

  Future<void> requestNewStream(
      {int? maxStreamingBitrate,
      int? audioStreamIndex,
      int? subtitleIndex}) async {
    var result = await _apiService.getStreamUrlAndPlaybackInfo(
      itemId: item.mediaSources!.first.id!,
      maxStreamingBitrate: maxStreamingBitrate ?? bitrate,
      audioStreamIndex: audioStreamIndex ?? audioStream.index,
      subtitleStreamIndex: subtitleIndex ?? subtitle.index,
      startTimeTicks: _player.state.position.inMilliseconds * 10000,
    );
    // update all mediastreams
    bitrate = maxStreamingBitrate ?? bitrate;
    item = result.$2;
    initAudioList();
    initSubtitleList();
    // map current subtitle
    audioStream = audioStreams.firstWhere((e) => audioStream.index == e.index);
    subtitle = subtitles.firstWhere((e) => subtitle.index == e.index);
    isTranscoding = item.mediaSources![0].transcodingUrl != null;
    await _player.open(Media(result.$1,
        httpHeaders: _apiService.headers,
        start: Duration(milliseconds: _player.state.position.inMilliseconds)));
  }

  Future<void> setAudio(MediaStream mediaStream) async {
    mediaStream = audioStreams
        .firstWhere((element) => element.index == mediaStream.index);
    if (isTranscoding && mediaStream.index != audioStream.index) {
      await requestNewStream(audioStreamIndex: mediaStream.index);
    } else {
      int index = mappedAudioStreams[mediaStream]!;
      _player.setAudioTrack(_player.state.tracks.audio[index]);
      audioStream = mediaStream;
    }
  }
}
