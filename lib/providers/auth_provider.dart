import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/secure_storage_provider.dart';
import 'package:jellyflix/services/auth_service.dart';

final authProvider = Provider<AuthService>((ref) {
  final apiService = ref.read(apiProvider);
  final secureStorageService = ref.read(secureStorageProvider);
  return AuthService(
      apiService: apiService, secureStorageService: secureStorageService);
});
