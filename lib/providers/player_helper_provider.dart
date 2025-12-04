import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/mpv_config_dialog.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/database_provider.dart';
import 'package:jellyflix/providers/download_provider.dart';
import 'package:jellyflix/providers/logger_provider.dart';
import 'package:jellyflix/services/api_service.dart';
import 'package:jellyflix/services/offline_player_helper.dart';
import 'package:jellyflix/services/stream_player_helper.dart';

final streamPlayerHelperProvider = FutureProvider.autoDispose
    .family<StreamPlayerHelper, String>((ref, itemId) async {
  ApiService apiService = ref.read(apiProvider);
  var item = await ref.read(apiProvider).getPlaybackInfo(itemId: itemId);
  final mpvConfig = ref.read(databaseProvider("settings")).get("mpvConfig") ??
      MpvConfigDialog.getDefaultConfig();
  final logger = ref.read(loggerProvider);
  return StreamPlayerHelper(
      playbackInfo: item,
      apiService: apiService,
      logger: logger,
      mpvConfig: mpvConfig);
});

final offlinePlayerHelperProvider = FutureProvider.autoDispose
    .family<OfflinePlayerHelper, String>((ref, itemId) async {
  var playbackInfo =
      await ref.read(downloadProvider(itemId)).getPlaybackInfoFromFile();
  var downloadMetadata = await ref.read(downloadProvider(itemId)).getMetadata();
  final mpvConfig = ref.read(databaseProvider("settings")).get("mpvConfig") ??
      MpvConfigDialog.getDefaultConfig();
  final logger = ref.read(loggerProvider);
  return OfflinePlayerHelper(
      playbackInfo: playbackInfo,
      downloadMetadata: downloadMetadata,
      logger: logger,
      mpvConfig: mpvConfig);
});
