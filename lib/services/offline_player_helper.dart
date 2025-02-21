import 'package:jellyflix/models/download_metadata.dart';
import 'package:jellyflix/services/player_helper.dart';

class OfflinePlayerHelper extends PlayerHelper {
  late final bool isTranscoding;
  late int bitrate;
  late final DownloadMetadata downloadMetadata;

  OfflinePlayerHelper({required playbackInfo})
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
}
