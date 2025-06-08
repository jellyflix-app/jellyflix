import 'package:flutter/material.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/download_settings_dialog.dart';
import 'package:jellyflix/components/item_list_tile.dart';
import 'package:jellyflix/components/jellyfin_image.dart';
import 'package:jellyflix/components/playback_progress_overlay.dart';
import 'package:jellyflix/models/bitrates.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/player_helper_provider.dart';
import 'package:tentacle/tentacle.dart';
import 'package:jellyflix/providers/connectivity_provider.dart';
import 'package:jellyflix/providers/database_provider.dart';
import 'package:jellyflix/providers/download_provider.dart';
import 'package:universal_io/io.dart';

class EpisodeListTile extends HookConsumerWidget {
  const EpisodeListTile(
      {super.key,
      required this.episode,
      required this.onSelected,
      required this.parentPath});

  final BaseItemDto episode;
  final Function(String) onSelected;
  final String parentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ValueNotifier<bool?> mark = useState(null);

    final ValueNotifier<int?> isDownloaded = useState(null);
    final isDownloading =
        useState(ref.read(downloadProvider(episode.id!)).isDownloading);

    mark.value = episode.userData!.played!;

    ref.read(downloadProvider(episode.id!)).calculateProgress().then((value) {
      isDownloaded.value = value;
    });

    return ItemListTile<BaseItemDto, String>(
      item: episode,
      title: Text(
        ("${episode.indexNumber == null ? "" : "${episode.indexNumber!}. "}${episode.name!}"),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(episode.runTimeTicks == null
          ? AppLocalizations.of(context)!.na
          : AppLocalizations.of(context)!
              .minutes((episode.runTimeTicks! / 10000000 / 60).round())),
      leading: JellyfinImage(
          id: episode.id!,
          type: ImageType.primary,
          blurHash: episode.imageBlurHashes?.primary?[episode.id!]),
      onTap: () async {
        var playbackInfo =
            await ref.read(streamPlayerHelperProvider(episode.id!).future);
        if (context.mounted) {
          context.pushNamed(parentPath + ScreenPaths.player,
              queryParameters: {
                "startTimeTicks":
                    episode.userData?.playbackPositionTicks?.toString(),
                "title": episode.name!
              },
              extra: playbackInfo);
        }
      },
      onSelectedMenuItem: onSelected,
      popupMenuEntries: [
        PopupMenuItem<String>(
          value: 'mark_as_played',
          child: !mark.value!
              ? ListTile(
                  leading: const Icon(Icons.check),
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: Text(
                    AppLocalizations.of(context)!.markAsPlayed,
                  ),
                )
              : ListTile(
                  leading: const Icon(Icons.close),
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: Text(
                    AppLocalizations.of(context)!.markAsUnplayed,
                  ),
                ),
        ),
        PopupMenuItem(
          value: 'download',
          child: !isDownloading.value && isDownloaded.value == null
              ? ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: Text(
                    AppLocalizations.of(context)!.download,
                  ),
                  onTap: () async {
                    if ((Platform.isAndroid || Platform.isIOS) &&
                        !(ref.read(connectivityProvider).isConnected)) {
                      return;
                    }

                    int downloadBitrate = await ref
                            .read(databaseProvider("settings"))
                            .get("downloadBitrate") ??
                        BitRates.defaultBitrate();

                    PlaybackInfoResponse downloadInfo = await ref
                        .read(downloadProvider(episode.id!))
                        .getDownloadInfo(downloadBitrate: downloadBitrate);

                    int audioCount = downloadInfo.mediaSources![0].mediaStreams!
                        .where((element) =>
                            element.type == MediaStreamType.audio &&
                            downloadInfo.mediaSources!.first.transcodingUrl !=
                                null)
                        .length;
                    int subtitleCount = downloadInfo
                        .mediaSources![0].mediaStreams!
                        .where((element) =>
                            element.type == MediaStreamType.subtitle &&
                            element.deliveryMethod ==
                                SubtitleDeliveryMethod.external_)
                        .length;

                    if (context.mounted &&
                        (audioCount > 1 || subtitleCount > 0)) {
                      var selectedSettings = await showDialog(
                        context: context,
                        builder: (context) {
                          return DownloadSettingsDialog(
                            downloadInfo: downloadInfo,
                          );
                        },
                      );

                      if (selectedSettings?.$1 == null &&
                              selectedSettings?.$2 == null ||
                          selectedSettings == null) {
                        return;
                      }

                      ref.read(downloadProvider(episode.id!)).downloadItem(
                          audioStreamIndex: selectedSettings.$1,
                          subtitleStreamIndex: selectedSettings.$2,
                          downloadBitrate: downloadBitrate);
                    } else {
                      ref
                          .read(downloadProvider(episode.id!))
                          .downloadItem(downloadBitrate: downloadBitrate);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text(AppLocalizations.of(context)!.startedDownload),
                        duration: const Duration(seconds: 1),
                      ));
                    }
                    isDownloading.value = true;
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                )
              : !isDownloading.value && isDownloaded.value == 100
                  ? ListTile(
                      leading: const Icon(Icons.delete_outline),
                      iconColor: Theme.of(context).colorScheme.primary,
                      title: Text(
                        AppLocalizations.of(context)!.deleteDownload,
                      ),
                      onTap: () {
                        ref
                            .read(downloadProvider(episode.id!))
                            .removeDownload();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              AppLocalizations.of(context)!.removedDownload),
                          duration: const Duration(seconds: 1),
                        ));
                        isDownloaded.value = null;
                        Navigator.of(context).pop();
                      },
                    )
                  : isDownloading.value
                      ? ListTile(
                          leading: const Icon(Icons.cancel_outlined),
                          iconColor: Theme.of(context).colorScheme.primary,
                          title: Text(
                            AppLocalizations.of(context)!.cancelDownload,
                          ),
                          onTap: () {
                            ref
                                .read(downloadProvider(episode.id!))
                                .cancelDownload();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .canceledDownload),
                              duration: const Duration(seconds: 1),
                            ));
                            isDownloading.value = false;
                            Navigator.of(context).pop();
                          },
                        )
                      : ListTile(
                          leading: const Icon(Icons.file_download_outlined),
                          iconColor: Theme.of(context).colorScheme.primary,
                          title: Text(
                            AppLocalizations.of(context)!.resumeDownload,
                          ),
                          onTap: () {
                            ref
                                .read(downloadProvider(episode.id!))
                                .resumeDownload();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .resumedDownload),
                              duration: const Duration(seconds: 1),
                            ));
                            isDownloading.value = true;
                            Navigator.of(context).pop();
                          },
                        ),
        )
      ],
      overlay: episode.userData!.playedPercentage != null
          ? PlaybackProgressOverlay(
              progress: (episode.userData!.playedPercentage! / 100))
          : mark.value == true
              ? Positioned(
                  bottom: 5.0,
                  right: 5.0,
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                )
              : const SizedBox.shrink(),
    );
  }
}
