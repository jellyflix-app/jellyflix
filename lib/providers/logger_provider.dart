import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/services/jfx_logger.dart';

final loggerProvider = Provider<JfxLogger>((ref) {
  return JfxLogger();
});
