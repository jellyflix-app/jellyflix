import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/download_icon.dart';
import 'package:jellyflix/components/download_settings_dialog.dart';
import 'package:jellyflix/models/bitrates.dart';
import 'package:jellyflix/providers/database_provider.dart';
import 'package:jellyflix/providers/download_provider.dart';
import 'package:tentacle/tentacle.dart';

class RoundedDownloadButton extends HookConsumerWidget {
  const RoundedDownloadButton({
    super.key,
    required this.itemId,
    required this.data,
  });

  final String itemId;
  final BaseItemDto data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ValueNotifier<int?> isDownloaded = useState(null);

    ref.read(downloadProvider(itemId)).downloadProgress(1).first.then((value) {
      isDownloaded.value = value;
    });

    return ElevatedButton(
        onPressed: () async {
          if (ref.read(downloadProvider(itemId)).isDownloading) {
            await ref.read(downloadProvider(itemId)).cancelDownload();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Canceled download"),
                duration: Duration(seconds: 1),
              ));
            }
          } else if (isDownloaded.value == null) {
            int downloadBitrate = await ref
                    .read(databaseProvider("settings"))
                    .get("downloadBitrate") ??
                BitRates.defaultBitrate();

            PlaybackInfoResponse downloadInfo = await ref
                .read(downloadProvider(itemId))
                .getDownloadInfo(downloadBitrate: downloadBitrate);

            int audioCount = downloadInfo.mediaSources![0].mediaStreams!
                .where((element) => element.type == MediaStreamType.audio)
                .length;
            int subtitleCount = downloadInfo.mediaSources![0].mediaStreams!
                .where((element) => element.type == MediaStreamType.subtitle)
                .length;

            if (context.mounted && (audioCount > 1 || subtitleCount > 0)) {
              (int?, int?) selectedSettings = await showDialog(
                context: context,
                builder: (context) {
                  return DownloadSettingsDialog(
                    downloadInfo: downloadInfo,
                  );
                },
              );
              if (selectedSettings.$1 == null && selectedSettings.$2 == null) {
                return;
              }

              ref.read(downloadProvider(itemId)).downloadItem(
                  audioStreamIndex: selectedSettings.$1,
                  subtitleStreamIndex: selectedSettings.$2,
                  downloadBitrate: downloadBitrate);
            } else {
              ref
                  .read(downloadProvider(itemId))
                  .downloadItem(downloadBitrate: downloadBitrate);
            }
            // trigger rebuild
            isDownloaded.value = 0;
            if (context.mounted) {
              // show snackbar
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(AppLocalizations.of(context)!.startedDownload),
                duration: const Duration(seconds: 1),
              ));
            }
          } else if (isDownloaded.value == 100) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!.removedDownload),
              duration: const Duration(seconds: 1),
            ));
            await ref.read(downloadProvider(itemId)).removeDownload();
            isDownloaded.value = null;
          } else {
            ref.read(downloadProvider(itemId)).resumeDownload();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(AppLocalizations.of(context)!.resumedDownload),
                duration: const Duration(seconds: 1),
              ));
            }
            // trigger rebuild
            isDownloaded.value = 0;
          }
        },
        style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            )),
        child: isDownloaded.value == 100
            ? const Icon(Icons.delete_outline)
            : isDownloaded.value == null &&
                    !ref.read(downloadProvider(itemId)).isDownloading
                ? const Icon(Icons.file_download_outlined)
                : switch (ref.watch(downloadProgressProvider(itemId))) {
                    AsyncError(:final error) =>
                      Center(child: Text('Error: $error')),
                    AsyncData(:final value) => DownloadIcon(
                        isDownloading:
                            ref.read(downloadProvider(itemId)).isDownloading,
                        progress: value,
                      ),
                    _ => const Center(child: CircularProgressIndicator()),
                  }

        // child: FutureBuilder(
        //   future: ref.read(downloadProvider(itemId)).calculateProgress(),
        //   builder: (context, snapshot) {
        //     if (snapshot.hasData) {
        //       if (snapshot.data == 100) {
        //         return const Icon(Icons.delete_outline);
        //       } else {
        //         return switch (ref.watch(downloadProgressProvider(itemId))) {
        //           AsyncError(:final error) =>
        //             Center(child: Text('Error: $error')),
        //           AsyncData(:final value) => DownloadIcon(
        //               isDownloading:
        //                   ref.read(downloadProvider(itemId)).isDownloading,
        //               progress: value,
        //             ),
        //           _ => const Center(child: CircularProgressIndicator()),
        //         };
        //       }
        //     } else {
        //       return const Icon(Icons.file_download_outlined);
        //     }
        //   },
        // ),
        );
  }
}
