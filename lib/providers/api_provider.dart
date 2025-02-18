import 'package:jellyflix/providers/logger_provider.dart';
import 'package:jellyflix/services/api_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final apiProvider = Provider((ref) {
  var logger = ref.read(loggerProvider);
  return ApiService(logger: logger);
});
