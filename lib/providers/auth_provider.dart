import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/models/auth_state.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/database_provider.dart';
import 'package:jellyflix/services/auth_service.dart';

final authProvider = Provider<AuthService>((ref) {
  final apiService = ref.read(apiProvider);
  final databaseService = ref.read(databaseProvider('auth'));
  return AuthService(apiService: apiService, databaseService: databaseService);
});

final StateProvider authStateProvider = StateProvider<AuthState?>((ref) {
  return null;
});

final updateServerReachableProvider =
    FutureProvider.autoDispose<void>((ref) async {
  final authService = ref.read(authProvider);
  bool? serverReachable = await authService.checkServerReachable();
  if (serverReachable == true) {
    bool loggedIn = await ref.read(authProvider).checkAuthentication();
    if (loggedIn &&
        ref.read(authStateProvider.notifier).state != AuthState.loggedIn) {
      ref.read(authStateStreamControllerProvider).add(AuthState.loggedIn);
      ref.read(authStateProvider.notifier).state = AuthState.loggedIn;
    } else if (!loggedIn &&
        ref.read(authStateProvider.notifier).state != AuthState.loggedOut) {
      ref.read(authStateStreamControllerProvider).add(AuthState.loggedOut);
      ref.read(authStateProvider.notifier).state = AuthState.loggedOut;
    }
  } else if (ref.read(authStateProvider.notifier).state != AuthState.offline) {
    ref.read(authStateStreamControllerProvider).add(AuthState.offline);
    ref.read(authStateProvider.notifier).state = AuthState.offline;
  }
});

final authStateStreamControllerProvider =
    StateProvider<StreamController<AuthState>>(
        (ref) => StreamController<AuthState>.broadcast());
