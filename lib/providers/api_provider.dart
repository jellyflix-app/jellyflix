import 'package:jellyflix/providers/database_provider.dart';
import 'package:jellyflix/services/api_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final apiProvider = Provider((ref) {
  return ApiService(
      ref.read(databaseProvider('settings')).get('disableImageCaching'));
});
