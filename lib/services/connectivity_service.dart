import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool isConnected = true;

  ConnectivityService() {
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<bool> checkConnectivityOnce() async {
    isConnected =
        (await Connectivity().checkConnectivity()) != ConnectivityResult.none;
    return isConnected;
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    isConnected = result != ConnectivityResult.none;
    _connectionStatusController.add(isConnected);
  }
}
