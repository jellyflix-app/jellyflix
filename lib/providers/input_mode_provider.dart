import 'package:hooks_riverpod/hooks_riverpod.dart';

enum InputMode {
  touch,
  mouse,
  keyboard,
  gamepad,
}

class InputModeNotifier extends StateNotifier<InputMode> {
  InputModeNotifier() : super(InputMode.mouse);

  void setInputMode(InputMode mode) {
    if (state != mode) {
      state = mode;
    }
  }

  bool get shouldShowFocusIndicator {
    return state == InputMode.keyboard || state == InputMode.gamepad;
  }
}

final inputModeProvider = StateNotifierProvider<InputModeNotifier, InputMode>(
  (ref) => InputModeNotifier(),
);

final shouldShowFocusIndicatorProvider = Provider<bool>((ref) {
  final mode = ref.watch(inputModeProvider);
  return mode == InputMode.keyboard || mode == InputMode.gamepad;
});
