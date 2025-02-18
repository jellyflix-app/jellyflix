import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/logger_provider.dart';
import 'package:jellyflix/services/connectivity_service.dart';

final connectivityProvider = Provider<ConnectivityService>((ref) {
  var logger = ref.read(loggerProvider);
  return ConnectivityService(logger: logger);
});
