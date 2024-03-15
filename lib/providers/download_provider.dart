import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/connectivity_provider.dart';
import 'package:jellyflix/services/download_service.dart';

final downloadProvider = Provider.family<DownloadService, String>(
    (ref, itemId) => DownloadService(ref.read(apiProvider),
        itemId: itemId, connectivityService: ref.read(connectivityProvider)));

final getDownloadsProvider = Provider.autoDispose<Future<List<String>>>(
    (ref) => DownloadService.getDownloadedItems());

final cancelAndDeleteDownloadProvider = Provider(
  (ref) => DownloadService.cancelAndDeleteAllDownloads(),
);
