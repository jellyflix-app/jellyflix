import 'package:jellyflix/services/api_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final apiProvider = Provider((ref) {
  return ApiService();
});
