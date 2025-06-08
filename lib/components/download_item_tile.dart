import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';
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
  final String parentBranch;

  const DownloadItemTile(
      {super.key, required this.itemId, required this.parentBranch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = useState(false);

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
            subtitle: ref.watch(downloadProgressProvider(itemId)).when(
                  data: (value) => Text(value == 100
                      ? '${(metaData.data!.runTimeTicks / 10000000 / 60).round()} min'
                      : '${value?.round()}% ${AppLocalizations.of(context)!.downloaded}'),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
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
                    context.pushNamed(parentBranch + ScreenPaths.player,
                        queryParameters: {
                          "startTimeTicks": "0",
                          "title": metaData.data!.name
                        },
                        extra: playerHelper);
                  }
                }
                subscription?.cancel();
              });
            },
            popupMenuEntries: [
              ...ref.watch(downloadProgressProvider(itemId)).when(
                    data: (value) {
                      if (value != 100 &&
                          !ref.read(downloadProvider(itemId)).isDownloading) {
                        return [
                          PopupMenuItem<String>(
                            value: "resume",
                            child: ListTile(
                              leading: const Icon(Icons.play_arrow_rounded),
                              iconColor: Theme.of(context).colorScheme.primary,
                              title: Text(
                                AppLocalizations.of(context)!.resumeDownload,
                              ),
                            ),
                          ),
                        ];
                      } else {
                        return [];
                      }
                    },
                    loading: () => [],
                    error: (error, stack) => [],
                  ),
              PopupMenuItem<String>(
                value: "delete",
                child: ref.read(downloadProvider(itemId)).isDownloading
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
                if (ref.read(downloadProvider(itemId)).isDownloading) {
                  await ref.read(downloadProvider(itemId)).cancelDownload();
                } else {
                  await ref.read(downloadProvider(itemId)).removeDownload();
                }
              }
              if (p0 == "resume") {
                await ref.read(downloadProvider(itemId)).resumeDownload();
              }
            },
          );
        });
  }
}
