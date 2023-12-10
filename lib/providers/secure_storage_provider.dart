import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/services/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
