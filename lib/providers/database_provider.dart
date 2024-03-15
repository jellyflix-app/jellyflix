import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/secure_storage_provider.dart';
import 'package:jellyflix/services/database_service.dart';

final databaseProvider =
    Provider.family<DatabaseService, String>((ref, boxName) {
  return DatabaseService(boxName, ref.read(secureStorageProvider));
});
