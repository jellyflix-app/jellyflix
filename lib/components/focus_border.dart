import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/input_mode_provider.dart';

class FocusBorder extends ConsumerStatefulWidget {
  final FocusNode focusNode;
  final Widget child;
  final BorderRadius? borderRadius;

  const FocusBorder({
    super.key,
    required this.focusNode,
    required this.child,
    this.borderRadius,
  });

  @override
  ConsumerState<FocusBorder> createState() => _FocusBorderState();
}

class _FocusBorderState extends ConsumerState<FocusBorder> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(FocusBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowFocusIndicator =
        ref.watch(shouldShowFocusIndicatorProvider);
    final hasFocus = widget.focusNode.hasFocus;
    final showBorder = hasFocus && shouldShowFocusIndicator;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(10.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: showBorder
            ? Border.all(
                color: primaryColor,
                width: 3.0,
              )
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.6),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: widget.child,
    );
  }
}
