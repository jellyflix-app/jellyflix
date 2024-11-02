import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/services/device_info_service.dart';

final appVersionProvider = FutureProvider<String?>((ref) async {
  return DeviceInfoService().getVersion();
});
