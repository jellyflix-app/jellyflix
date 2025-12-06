import 'dart:async';

import 'package:jellyflix/models/download_metadata.dart';
import 'package:jellyflix/services/player_helper.dart';
import 'package:media_kit/media_kit.dart';
import 'package:tentacle/tentacle.dart';

class OfflinePlayerHelper extends PlayerHelper {
  late int bitrate;
  late final DownloadMetadata downloadMetadata;

  OfflinePlayerHelper(
      {required playbackInfo,
      required this.downloadMetadata,
      required logger,
      String? mpvConfig})
      : super(
            playbackInfo: playbackInfo, logger: logger, mpvConfig: mpvConfig) {
    audioStream = getDefaultAudio();
    subtitle = getDefaultSubtitle();
    isSubtitleEnabled = subtitle.index != -1;
    showBitrate = false;
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
  Future<void> initStream(int startTimeTicks) async {
    String streamUrl = downloadMetadata.path!;
    player.open(
        Media(streamUrl, start: Duration(microseconds: startTimeTicks ~/ 10)));
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
  }

  // no additional logic needed for offline playback
  @override
  Future<void> completedPlayback() async {}

  // no additional logic needed for offline playback
  @override
  Future<void> backButtonPressed() async {}

  @override
  Future<void> setAudio(MediaStream mediaStream) async {
    mediaStream = audioStreams
        .firstWhere((element) => element.index == mediaStream.index);
    int index = mappedAudioStreams[mediaStream]!;
    player.setAudioTrack(player.state.tracks.audio[index]);
    audioStream = mediaStream;
  }

  @override
  Future<void> setSubtitle(MediaStream mediaStream) async {
    mediaStream =
        subtitles.firstWhere((element) => element.index == mediaStream.index);
    if (mediaStream.deliveryMethod == SubtitleDeliveryMethod.external_) {
      // load subtitle from file
      SubtitleTrack externalSubtitle =
          SubtitleTrack.uri(mediaStream.deliveryUrl!);
      // external subtitles
      await player.setSubtitleTrack(externalSubtitle);
      isSubtitleEnabled = true;
      subtitle = mediaStream;
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
}
