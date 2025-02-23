import 'dart:async';

import 'package:jellyflix/models/download_metadata.dart';
import 'package:jellyflix/services/player_helper.dart';
import 'package:media_kit/media_kit.dart';

class OfflinePlayerHelper extends PlayerHelper {
  late int bitrate;
  late final DownloadMetadata downloadMetadata;

  OfflinePlayerHelper({required playbackInfo, required this.downloadMetadata})
      : super(playbackInfo: playbackInfo) {
    audioStream = getDefaultAudio();
    subtitle = getDefaultSubtitle();
    isSubtitleEnabled = subtitle.index != -1;
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
  Future<void> initStream(int startTimeTicks, Timer? playbackTimer) async {
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

  @override
  Future<void> completedPlayback() async {}

  @override
  void backButtonPressed() async {}
}
