import 'package:hooks_riverpod/hooks_riverpod.dart';

class GlobalState {
  final mediaPlaybackIsLoading = StateProvider<bool>((ref) => false);
}

final globalState = GlobalState();
