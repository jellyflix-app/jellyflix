import 'dart:async';

import 'package:jellyflix/services/api_service.dart';
import 'package:jellyflix/services/player_helper.dart';
import 'package:media_kit/media_kit.dart';
import 'package:tentacle/tentacle.dart';

class StreamPlayerHelper extends PlayerHelper {
  late final ApiService _apiService;
  late int bitrate;
  Timer? playbackTimer;

  StreamPlayerHelper(
      {required playbackInfo,
      required apiService,
      required logger,
      String? mpvConfig})
      : _apiService = apiService,
        super(
            playbackInfo: playbackInfo, logger: logger, mpvConfig: mpvConfig) {
    bitrate = getDefaultBitrate();
    isSubtitleEnabled = subtitle.index != -1;
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
    var result = await _apiService.getPlaybackInfo(
      itemId: playbackInfo.mediaSources!.first.id!,
      maxStreamingBitrate: maxStreamingBitrate ?? bitrate,
      audioStreamIndex: audioStreamIndex ?? audioStream.index,
      subtitleStreamIndex: subtitleIndex ?? subtitle.index,
      startTimeTicks: player.state.position.inMilliseconds * 10000,
    );
    // update all mediastreams
    bitrate = maxStreamingBitrate ?? bitrate;
    playbackInfo = result;
    initAudioList();
    initSubtitleList();
    // map current subtitle
    audioStream = audioStreams.firstWhere((e) => audioStream.index == e.index);
    subtitle = subtitles.firstWhere((e) => subtitle.index == e.index);
    isTranscoding = playbackInfo.mediaSources![0].transcodingUrl != null;
    await player.open(Media(_apiService.getStreamUrl(playbackInfo),
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

  @override
  Future<void> initStream(int startTimeTicks) async {
    String streamUrl = _apiService.getStreamUrl(playbackInfo);
    await player.open(Media(streamUrl,
        httpHeaders: _apiService.headers,
        start: Duration(microseconds: startTimeTicks ~/ 10)));
    StreamSubscription? trackStream;
    trackStream = player.stream.tracks.listen((event) {
      List<AudioTrack> audioTracks = event.audio;
      List<SubtitleTrack> subtitleTracks = event.subtitle;
      if (audioTracks.length > 2 || subtitleTracks.length > 2) {
        setAudio(audioStream);

        if (getDefaultSubtitle().index != -1) {
          enableSubtitle();
        }

        // only run until initial load
        trackStream?.cancel();
      }
    });

    _apiService.reportStartPlayback(startTimeTicks);

    playbackTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _apiService.reportPlaybackProgress(
        player.state.position.inMilliseconds * 10000,
        audioStreamIndex: audioStream.index,
        subtitleStreamIndex: subtitle.index,
      );
    });
  }

  @override
  Future<void> completedPlayback() async {
    playbackTimer?.cancel();
    await _apiService
        .reportStopPlayback(player.state.position.inMilliseconds * 10000);
  }

  @override
  Future<void> backButtonPressed() async {
    playbackTimer?.cancel();
    _apiService
        .reportStopPlayback(player.state.position.inMilliseconds * 10000);
  }
}
