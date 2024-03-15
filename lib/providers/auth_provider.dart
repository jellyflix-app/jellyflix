import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/database_provider.dart';
import 'package:jellyflix/services/auth_service.dart';

final authProvider = Provider<AuthService>((ref) {
  final apiService = ref.read(apiProvider);
  final databaseService = ref.read(databaseProvider('auth'));
  return AuthService(apiService: apiService, databaseService: databaseService);
});
