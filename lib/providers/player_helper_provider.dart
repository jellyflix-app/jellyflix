import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/download_provider.dart';
import 'package:jellyflix/services/api_service.dart';
import 'package:jellyflix/services/offline_player_helper.dart';
import 'package:jellyflix/services/stream_player_helper.dart';

final streamPlayerHelperProvider = FutureProvider.autoDispose
    .family<StreamPlayerHelper, String>((ref, itemId) async {
  ApiService apiService = ref.read(apiProvider);
  var item = await ref.read(apiProvider).getPlaybackInfo(itemId: itemId);
  return StreamPlayerHelper(playbackInfo: item, apiService: apiService);
});

final offlinePlayerHelperProvider = FutureProvider.autoDispose
    .family<OfflinePlayerHelper, String>((ref, itemId) async {
  var playbackInfo =
      await ref.read(downloadProvider(itemId)).getPlaybackInfoFromFile();
  var downloadMetadata = await ref.read(downloadProvider(itemId)).getMetadata();
  return OfflinePlayerHelper(
      playbackInfo: playbackInfo, downloadMetadata: downloadMetadata);
});
