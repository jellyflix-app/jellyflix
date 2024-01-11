import 'package:flutter/material.dart';

class PlaybackProgressOverlay extends StatelessWidget {
  final double? progress;

  const PlaybackProgressOverlay({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (progress == null) {
      return const SizedBox.shrink();
    }
    return Positioned(
        bottom: 5,
        left: 5,
        right: 5,
        child: LinearProgressIndicator(
          borderRadius: BorderRadius.circular(100.0),
          minHeight: 5,
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.5),
          color: Theme.of(context).buttonTheme.colorScheme!.onPrimary,
        ));
  }
}
