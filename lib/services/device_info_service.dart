import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoService {
  final deviceInfoPlugin = DeviceInfoPlugin();
  BaseDeviceInfo? _deviceInfo;

  Future<String?> getDeviceModel() async {
    if (_deviceInfo != null) {
      return _deviceInfo!.data['model'];
    }
    BaseDeviceInfo deviceInfo = await deviceInfoPlugin.deviceInfo;
    _deviceInfo = deviceInfo;
    return deviceInfo.data['model'];
  }

  Future<String?> getDeviceId() async {
    if (_deviceInfo != null) {
      return _deviceInfo!.data['systemGUID'];
    }
    BaseDeviceInfo deviceInfo = await deviceInfoPlugin.deviceInfo;
    _deviceInfo = deviceInfo;
    return deviceInfo.data['systemGUID'];
  }

  Future<String?> getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
