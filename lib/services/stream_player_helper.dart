import 'package:jellyflix/models/bitrates.dart';
import 'package:jellyflix/services/api_service.dart';
import 'package:jellyflix/services/player_helper.dart';
import 'package:media_kit/media_kit.dart';
import 'package:tentacle/tentacle.dart';

class StreamPlayerHelper extends PlayerHelper {
  Map<int, String> bitrateMap = BitRates().map;

  late final ApiService _apiService;
  late final bool isTranscoding;
  late int bitrate;

  StreamPlayerHelper({required playbackInfo, required apiService})
      : super(playbackInfo: playbackInfo) {
    bitrate = getDefaultBitrate();
    isSubtitleEnabled = subtitle.index != -1;
    isTranscoding = playbackInfo.mediaSources![0].transcodingUrl != null;
    _apiService = apiService;
  }

  Map<int, String> getBitrateMap() {
    // add orignal bitrate at the beginning
    bitrateMap[playbackInfo.mediaSources![0].bitrate ?? 0] =
        "Original ${playbackInfo.mediaSources![0].bitrate! ~/ 1000000} Mb/s";
    // add original bitrate at the beginning and sort the rest descending
    bitrateMap = Map.fromEntries(
      bitrateMap.entries.toList()..sort((e1, e2) => e2.key.compareTo(e1.key)),
    );
    // remove bitrates that are higher than the original
    bitrateMap.removeWhere(
        (key, value) => key > playbackInfo.mediaSources![0].bitrate!);

    return bitrateMap;
  }

  int getDefaultBitrate() {
    return playbackInfo.mediaSources![0].bitrate ?? 0;
  }

  @override
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
      ...playbackInfo.mediaSources![0].mediaStreams!
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

  @override
  void initAudioList() {
    // values are the index of the embedded audio stream
    audioStreams = playbackInfo.mediaSources![0].mediaStreams!
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

  @override
  MediaStream getDefaultAudio() {
    int index = playbackInfo.mediaSources![0].defaultAudioStreamIndex ?? -1;
    return audioStreams.firstWhere((element) => element.index == index);
  }

  @override
  MediaStream getDefaultSubtitle() {
    int index = playbackInfo.mediaSources![0].defaultSubtitleStreamIndex ?? -1;
    return subtitles.firstWhere((element) => element.index == index);
  }

  @override
  Future<void> setSubtitle(MediaStream mediaStream) async {
    mediaStream =
        subtitles.firstWhere((element) => element.index == mediaStream.index);
    if (mediaStream.deliveryMethod == SubtitleDeliveryMethod.external_) {
      // external subtitles
      SubtitleTrack externalSubtitle = await _apiService
          .getExternalSubtitleTrack(deliveryUrl: mediaStream.deliveryUrl!);
      player.setSubtitleTrack(externalSubtitle);
      isSubtitleEnabled = true;
      subtitle = mediaStream;
    } else if (isTranscoding &&
        mediaStream.index != subtitle.index &&
        subtitle.deliveryMethod == SubtitleDeliveryMethod.embed) {
      await requestNewStream(subtitleIndex: mediaStream.index);
    } else {
      if (mediaStream.index == -1) {
        // no subtitles is track with index 1
        player.setSubtitleTrack(player.state.tracks.subtitle[1]);
        isSubtitleEnabled = false;
      } else {
        int index = mappedSubtitles[mediaStream]!;
        player.setSubtitleTrack(player.state.tracks.subtitle[index]);
        isSubtitleEnabled = true;
        subtitle = mediaStream;
      }
    }
  }

  @override
  Future<void> disableSubtitle() async {
    player.setSubtitleTrack(player.state.tracks.subtitle[1]);
    isSubtitleEnabled = false;
  }

  @override
  Future<void> enableSubtitle() async {
    if (subtitle.index == -1) {
      // index 0 is no subtitle
      await setSubtitle(subtitles[1]);
    } else {
      await setSubtitle(subtitle);
    }
  }

  @override
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
      itemId: playbackInfo.mediaSources!.first.id!,
      maxStreamingBitrate: maxStreamingBitrate ?? bitrate,
      audioStreamIndex: audioStreamIndex ?? audioStream.index,
      subtitleStreamIndex: subtitleIndex ?? subtitle.index,
      startTimeTicks: player.state.position.inMilliseconds * 10000,
    );
    // update all mediastreams
    bitrate = maxStreamingBitrate ?? bitrate;
    playbackInfo = result.$2;
    initAudioList();
    initSubtitleList();
    // map current subtitle
    audioStream = audioStreams.firstWhere((e) => audioStream.index == e.index);
    subtitle = subtitles.firstWhere((e) => subtitle.index == e.index);
    isTranscoding = playbackInfo.mediaSources![0].transcodingUrl != null;
    await player.open(Media(result.$1,
        httpHeaders: _apiService.headers,
        start: Duration(milliseconds: player.state.position.inMilliseconds)));
  }

  @override
  Future<void> setAudio(MediaStream mediaStream) async {
    mediaStream = audioStreams
        .firstWhere((element) => element.index == mediaStream.index);
    if (isTranscoding && mediaStream.index != audioStream.index) {
      await requestNewStream(audioStreamIndex: mediaStream.index);
    } else {
      int index = mappedAudioStreams[mediaStream]!;
      player.setAudioTrack(player.state.tracks.audio[index]);
      audioStream = mediaStream;
    }
  }

  saveToFile() {}
}
