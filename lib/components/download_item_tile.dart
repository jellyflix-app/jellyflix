import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/item_list_tile.dart';
import 'package:jellyflix/models/download_metadata.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/download_provider.dart';
import 'package:jellyflix/providers/player_helper_provider.dart';
import 'package:jellyflix/services/player_helper.dart';
import 'package:tentacle/tentacle.dart';
import 'package:universal_io/io.dart';

class DownloadItemTile extends HookConsumerWidget {
  final String itemId;

  const DownloadItemTile({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = useState(false);
    final isDownloading =
        useState(ref.read(downloadProvider(itemId)).isDownloading);
    final downloadProgress = useState(0);

    return FutureBuilder(
        future: ref.read(downloadProvider(itemId)).getMetadata(),
        builder: (context, metaData) {
          if (!metaData.hasData || dismissed.value) {
            return const SizedBox.shrink();
          }

          return ItemListTile<DownloadMetadata, String>(
            height: MediaQuery.of(context).size.width >= 640 ? 150 : 100,
            item: metaData.data!,
            title: Text(
              metaData.data!.type == BaseItemKind.episode
                  ? "${metaData.data!.seriesName} (S${metaData.data!.parentIndexNumber.toString().padLeft(2, '0')}E${metaData.data!.indexNumber.toString().padLeft(2, '0')})\n${metaData.data!.name}"
                  : metaData.data!.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: isDownloading.value
                ? switch (ref.watch(downloadProgressProvider(itemId))) {
                    AsyncError(:final error) =>
                      Center(child: Text('Error: $error')),
                    AsyncData(:final value) => Text(
                        '${value?.round()}% ${AppLocalizations.of(context)!.downloaded}'),
                    _ => const Center(child: CircularProgressIndicator()),
                  }
                : FutureBuilder(
                    future:
                        ref.read(downloadProvider(itemId)).calculateProgress(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        //downloadProgress.value = snapshot.data!;
                        if (snapshot.data == 100) {
                          return Text(
                              "${(metaData.data!.runTimeTicks / 10000000 / 60).round()} min");
                        }
                        return Text(
                          "${snapshot.data!.round()}% ${AppLocalizations.of(context)!.downloaded}",
                        );
                      } else {
                        return Text(AppLocalizations.of(context)!
                            .quickConnectErrorUnknown);
                      }
                    },
                  ),
            leading: FutureBuilder(
                future:
                    ref.read(downloadProvider(itemId)).getMetadataImagePath(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(snapshot.data!),
                          fit: BoxFit.fill,
                        ),
                      ),
                    );
                  }
                  return const CircularProgressIndicator();
                }),
            onTap: () async {
              StreamSubscription? subscription;
              subscription = ref
                  .read(downloadProvider(itemId))
                  .downloadProgress(1)
                  .listen((progress) async {
                if (progress == 100) {
                  PlayerHelper playerHelper = await ref
                      .read(offlinePlayerHelperProvider(itemId).future);

                  if (context.mounted) {
                    context.push(
                        Uri(
                                path: ScreenPaths.player,
                                queryParameters: {"startTimeTicks": "0"})
                            .toString(),
                        extra: playerHelper);
                  }
                  // context.push(
                  //   Uri(
                  //     path: ScreenPaths.player,
                  //   ).toString(),
                  //   extra: metaData.data!.path,
                  // );
                }
                subscription?.cancel();
              });
            },
            popupMenuEntries: [
              if (!isDownloading.value && downloadProgress.value != 100)
                PopupMenuItem(
                  value: "resume",
                  child: ListTile(
                    leading: const Icon(Icons.play_arrow_rounded),
                    iconColor: Theme.of(context).colorScheme.primary,
                    title: Text(
                      AppLocalizations.of(context)!.resumeDownload,
                    ),
                  ),
                ),
              PopupMenuItem(
                value: "delete",
                child: isDownloading.value
                    ? ListTile(
                        leading: const Icon(Icons.close_rounded),
                        iconColor: Theme.of(context).colorScheme.primary,
                        title: Text(
                          AppLocalizations.of(context)!.cancelDownload,
                        ),
                      )
                    : ListTile(
                        leading: const Icon(Icons.delete_outline_rounded),
                        iconColor: Theme.of(context).colorScheme.primary,
                        title: Text(
                          AppLocalizations.of(context)!.deleteDownload,
                        ),
                      ),
              ),
            ],
            onSelectedMenuItem: (p0) async {
              if (p0 == "delete") {
                dismissed.value = true;
                if (isDownloading.value) {
                  await ref.read(downloadProvider(itemId)).cancelDownload();
                } else {
                  await ref.read(downloadProvider(itemId)).removeDownload();
                }
              }
              if (p0 == "resume" && !isDownloading.value) {
                await ref.read(downloadProvider(itemId)).resumeDownload();
                isDownloading.value = true;
              }
            },
          );
        });
  }
}
