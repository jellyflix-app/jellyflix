import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/services/api_service.dart';
import 'package:jellyflix/services/playback_helper_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:tentacle/tentacle.dart';

final playbackHelperProvider = Provider.autoDispose
    .family<PlaybackHelperService, (PlaybackInfoResponse, Player)>((ref, item) {
  ApiService apiService = ref.read(apiProvider);
  return PlaybackHelperService(
      item: item.$1, player: item.$2, apiService: apiService);
});
