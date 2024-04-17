import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/services/playback_helper_service.dart';
import 'package:tentacle/tentacle.dart';

final playbackHelperProvider = Provider.autoDispose
    .family<PlaybackHelperService, PlaybackInfoResponse>((ref, item) {
  return PlaybackHelperService(item: item);
});
