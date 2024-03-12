import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DownloadIcon extends HookConsumerWidget {
  final int? progress;
  final bool isDownloading;
  const DownloadIcon(
      {super.key, required this.progress, required this.isDownloading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (progress == 100) {
      return const Icon(Icons.delete_outline_rounded);
    } else if (progress != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress! / 100,
            valueColor:
                AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
          ),
          isDownloading
              ? const Icon(Icons.close)
              : const Icon(Icons.file_download_outlined)
        ],
      );
    } else {
      return const Icon(Icons.file_download_outlined);
    }
  }
}
