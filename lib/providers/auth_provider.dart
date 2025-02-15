import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/models/auth_state.dart';
import 'package:jellyflix/models/user.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/database_provider.dart';
import 'package:jellyflix/providers/logger_provider.dart';
import 'package:jellyflix/services/auth_service.dart';

final authProvider = Provider<AuthService>((ref) {
  final apiService = ref.read(apiProvider);
  final databaseService = ref.read(databaseProvider('auth'));
  final logger = ref.read(loggerProvider);
  return AuthService(
      apiService: apiService, databaseService: databaseService, logger: logger);
});

final StateProvider authStateProvider = StateProvider<AuthState?>((ref) {
  return null;
});

final updateServerReachableProvider =
    FutureProvider.autoDispose<void>((ref) async {
  var logger = ref.read(loggerProvider);
  final authService = ref.read(authProvider);
  bool? serverReachable = await authService.checkServerReachable();
  logger.verbose("Auth: Server reachable: $serverReachable");
  if (serverReachable == true) {
    logger.verbose("Auth: Server is reachable");
    bool loggedIn = await ref.read(authProvider).checkAuthentication();
    if (loggedIn &&
        ref.read(authStateProvider.notifier).state != AuthState.loggedIn) {
      ref.read(authStateStreamControllerProvider).add(AuthState.loggedIn);
      ref.read(authStateProvider.notifier).state = AuthState.loggedIn;
      logger.verbose("Auth: User is logged in");
    } else if (!loggedIn &&
        ref.read(authStateProvider.notifier).state != AuthState.loggedOut) {
      ref.read(authStateStreamControllerProvider).add(AuthState.loggedOut);
      ref.read(authStateProvider.notifier).state = AuthState.loggedOut;
      logger.verbose("Auth: User is logged out");
    }
  } else if (serverReachable == false &&
      ref.read(authStateProvider.notifier).state != AuthState.offline) {
    ref.read(authStateStreamControllerProvider).add(AuthState.offline);
    ref.read(authStateProvider.notifier).state = AuthState.offline;
    logger.verbose("Auth: Server is not reachable and AuthState is offline");
  } else if (serverReachable == null &&
      ref.read(authStateProvider.notifier).state != AuthState.unknown) {
    ref.read(authStateStreamControllerProvider).add(AuthState.unknown);
    ref.read(authStateProvider.notifier).state = AuthState.unknown;
    logger.verbose(
        "Auth: Server reachability is unknown and AuthState is unknown");
  }
});

final authStateStreamControllerProvider =
    StateProvider<StreamController<AuthState>>(
        (ref) => StreamController<AuthState>.broadcast());

final allProfilesProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  return ref.read(authProvider).getAllProfiles();
});
