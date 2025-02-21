import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/services/api_service.dart';
import 'package:jellyflix/services/stream_player_helper.dart';
import 'package:tentacle/tentacle.dart';

final playerHelperProvider = Provider.autoDispose
    .family<StreamPlayerHelper, PlaybackInfoResponse>((ref, item) {
  ApiService apiService = ref.read(apiProvider);
  return StreamPlayerHelper(playbackInfo: item, apiService: apiService);
});
