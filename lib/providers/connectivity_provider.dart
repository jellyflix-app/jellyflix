import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/services/connectivity_service.dart';

final connectivityProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});
