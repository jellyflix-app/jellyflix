import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/navigation/app_router.dart';

final routerProvider = Provider((ref) => AppRouter(ref));
