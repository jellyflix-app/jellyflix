import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:openapi/openapi.dart';
import 'package:universal_io/io.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/item_list_tile.dart';
import 'package:jellyflix/models/download_metadata.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/download_provider.dart';

class DownloadScreen extends HookConsumerWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.downloads),
      ),
      body: FutureBuilder(
          future: ref.read(getDownloadsProvider),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return DownloadItemTile(index: snapshot.data![index]);
                },
              );
            }
            return Center(
              child: Text(AppLocalizations.of(context)!.noDownloads),
            );
          }),
    );
  }
}

class DownloadItemTile extends HookConsumerWidget {
  final String index;

  const DownloadItemTile({super.key, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = useState(false);
    final isDownloading =
        useState(ref.read(downloadProvider(index)).isDownloading);

    return FutureBuilder(
        future: ref.read(downloadProvider(index)).getMetadata(),
        builder: (context, metaData) {
          if (!metaData.hasData || dismissed.value) {
            return const SizedBox.shrink();
          }
          return StreamBuilder(
              stream: ref.read(downloadProvider(index)).downloadProgess(5),
              builder: (context, snapshot) {
                return ItemListTile<DownloadMetadata, String>(
                  height: MediaQuery.of(context).size.width >= 640 ? 150 : 100,
                  item: metaData.data!,
                  title: Text(
                    metaData.data!.type == BaseItemKind.episode
                        ? "${metaData.data!.seriesName} (S${metaData.data!.parentIndexNumber.toString().padLeft(2, '0')}E${metaData.data!.indexNumber.toString().padLeft(2, '0')})\n${metaData.data!.name}"
                        : metaData.data!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Builder(
                    builder: (context) {
                      if (snapshot.hasData) {
                        if (snapshot.data == 100) {
                          return Text(
                              "${(metaData.data!.runTimeTicks / 10000000 / 60).round()} min");
                        }
                        return Text(
                          "${snapshot.data!.round()}% ${AppLocalizations.of(context)!.downloaded}",
                        );
                      }
                      return Text(
                          "0% ${AppLocalizations.of(context)!.downloaded}");
                    },
                  ),
                  leading: FutureBuilder(
                      future: ref
                          .read(downloadProvider(index))
                          .getMetadataImagePath(),
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
                    if (await ref
                                .read(downloadProvider(index))
                                .downloadProgess(1)
                                .last ==
                            100 &&
                        context.mounted) {
                      context.push(
                        Uri(
                          path: ScreenPaths.offlinePlayer,
                        ).toString(),
                        extra: metaData.data!.path,
                      );
                    }
                  },
                  popupMenuEntries: [
                    if (!ref.read(downloadProvider(index)).isDownloading &&
                        snapshot.data != 100)
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
                        await ref
                            .read(downloadProvider(index))
                            .cancelDownload();
                      } else {
                        await ref
                            .read(downloadProvider(index))
                            .removeDownload();
                      }
                    }
                    if (p0 == "resume" && !isDownloading.value) {
                      await ref.read(downloadProvider(index)).resumeDownload();
                      isDownloading.value = true;
                    }
                  },
                );
              });
        });
  }
}
