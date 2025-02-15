import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jellyflix/services/jfx_logger.dart';

class ConnectivityService {
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool isConnected = true;
  final JfxLogger _logger;

  ConnectivityService({required JfxLogger logger}) : _logger = logger {
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<bool> checkConnectivityOnce() async {
    List<ConnectivityResult> result = await Connectivity().checkConnectivity();
    isConnected = result.any((res) =>
        res != ConnectivityResult.none && res != ConnectivityResult.other);
    _logger.verbose(
        'ConnectivityService: Checked once: isConnected: $isConnected');
    return isConnected;
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    isConnected = result.any((res) =>
        res != ConnectivityResult.none && res != ConnectivityResult.other);
    _connectionStatusController.add(isConnected);
    _logger.verbose('ConnectivityService: Updated: isConnected: $isConnected');
  }
}
