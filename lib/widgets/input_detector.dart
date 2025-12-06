import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/input_mode_provider.dart';

class InputDetector extends ConsumerStatefulWidget {
  final Widget child;

  const InputDetector({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<InputDetector> createState() => _InputDetectorState();
}

class _InputDetectorState extends ConsumerState<InputDetector> {
  DateTime? _lastPointerEventTime;
  static const _pointerEventDebounce = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    // Listen to hardware keyboard events
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    // Only respond to key down events to avoid duplicate triggers
    if (event is KeyDownEvent) {
      ref.read(inputModeProvider.notifier).setInputMode(InputMode.keyboard);
    }
    // Return false to allow the event to continue propagating
    return false;
  }

  void _handlePointerEvent(PointerEvent event) {
    final now = DateTime.now();

    // Debounce pointer events to avoid excessive updates
    if (_lastPointerEventTime != null &&
        now.difference(_lastPointerEventTime!) < _pointerEventDebounce) {
      return;
    }

    _lastPointerEventTime = now;

    if (event is PointerHoverEvent) {
      // Mouse movement (desktop)
      ref.read(inputModeProvider.notifier).setInputMode(InputMode.mouse);
    } else if (event is PointerDownEvent) {
      // Distinguish between mouse click and touch
      if (event.kind == PointerDeviceKind.mouse) {
        ref.read(inputModeProvider.notifier).setInputMode(InputMode.mouse);
      } else if (event.kind == PointerDeviceKind.touch) {
        ref.read(inputModeProvider.notifier).setInputMode(InputMode.touch);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerEvent,
      onPointerHover: _handlePointerEvent,
      child: widget.child,
    );
  }
}
