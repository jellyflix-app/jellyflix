import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/jfx_layout.dart';
import 'package:jellyflix/components/rounded_download_button.dart';
import 'package:tentacle/tentacle.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class JfxButtonRow extends StatelessWidget {
  final BuildContext context;
  final WidgetRef ref;
  final BaseItemDto data;
  final String itemId;
  final ValueNotifier<bool> addtlVersionsHovered;
  final ValueNotifier<bool> playButtonHovered;
  final ValueNotifier<bool> onWatchlist;
  final ValueNotifier<bool> markedAsPlayed;
  final StreamController<List<BaseItemDto>> streamController;
  final Function goToPlayerScreen;

  const JfxButtonRow(
      {Key? key,
      required this.context,
      required this.ref,
      required this.data,
      required this.itemId,
      required this.addtlVersionsHovered,
      required this.playButtonHovered,
      required this.onWatchlist,
      required this.markedAsPlayed,
      required this.streamController,
      required this.goToPlayerScreen})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildRow(
        context,
        ref,
        data,
        itemId,
        addtlVersionsHovered,
        playButtonHovered,
        onWatchlist,
        markedAsPlayed,
        streamController,
        goToPlayerScreen);
  }

  Widget buildRow(
      BuildContext context,
      WidgetRef ref,
      BaseItemDto data,
      String itemId,
      ValueNotifier<bool> addtlVersionsHovered,
      ValueNotifier<bool> playButtonHovered,
      ValueNotifier<bool> onWatchList,
      ValueNotifier<bool> markedAsPlayed,
      StreamController<List<BaseItemDto>> streamController,
      Function goToPlayerScreen) {
    JfxLayout layout = JfxLayout.scalingLayout(context);

    Widget buildPlayButton(
        BuildContext context, WidgetRef ref, data, JfxLayout layout) {
      return ElevatedButton.icon(
          onPressed: () async {
            String itemId;
            int playbackStartTicks = 0;
            if (data.type == BaseItemKind.series) {
              List<BaseItemDto> continueWatching = await ref
                  .read(apiProvider)
                  .getContinueWatching(parentId: data.id!);
              if (continueWatching.isNotEmpty) {
                itemId = continueWatching.first.id!;
                playbackStartTicks =
                    continueWatching.first.userData!.playbackPositionTicks!;
              } else {
                List<BaseItemDto> result = await ref
                    .read(apiProvider)
                    .getNextUpEpisode(seriesId: data.id!);
                if (result.isNotEmpty) {
                  itemId = result.first.id!;
                } else {
                  List<BaseItemDto> episodes =
                      await ref.read(apiProvider).getEpisodes(data.id!);
                  itemId = episodes.first.id!;
                }
              }
            } else {
              itemId = data.mediaSources!.first.id!;
              playbackStartTicks = data.userData!.playbackPositionTicks!;
            }
            if (context.mounted) {
              await goToPlayerScreen(ref, itemId, playbackStartTicks, context);
            }
          },
          icon: const Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: SizedBox(width: 10, child: Icon(Icons.play_arrow_rounded)),
          ),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
                style: layout.text.bodyLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                AppLocalizations.of(context)!.play),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ));
    }

    Widget buildAdditionalVersionsButton(
      BuildContext context,
      data,
      JfxLayout layout,
      ValueNotifier<bool> hovered,
    ) {
      return SizedBox(
        child: Material(
          child: PopupMenuButton(
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry> popUpItems = [];
              for (var element in data.mediaSources!) {
                popUpItems.add(PopupMenuItem(
                  value: element.id,
                  child: Text(element.name!, style: layout.text.bodyLarge),
                ));
              }
              return popUpItems;
            },
            tooltip: "",
            onSelected: (value) async {
              await goToPlayerScreen(
                  ref, value, data.userData!.playbackPositionTicks!, context);
            },
            child: MouseRegion(
              onEnter: (event) {
                hovered.value = true;
              },
              onExit: (event) {
                hovered.value = false;
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100.0),
                  color: hovered.value
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.9)
                      : Theme.of(context).colorScheme.primary,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 5.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                          style: layout.text.bodyLarge!.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          AppLocalizations.of(context)!.play),
                      const SizedBox(width: 5.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget buildFavoriteButton(BuildContext context, WidgetRef ref, itemId,
        JfxLayout layout, ValueNotifier<bool> favorite) {
      return Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100.0),
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: ElevatedButton(
          onPressed: () async {
            await ref
                .read(apiProvider)
                .updateWatchlist(itemId, !favorite.value);
            favorite.value = !favorite.value;

            if (context.mounted) {
              // show snackbar
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    favorite.value
                        ? AppLocalizations.of(context)!.addedToWatchlist
                        : AppLocalizations.of(context)!.removedFromWatchlist,
                    style: layout.text.bodyLarge!
                        .copyWith(color: layout.color.onPrimary)),
                duration: const Duration(seconds: 1),
              ));
            }
          },
          style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              )),
          child: Icon(
            favorite.value ? Icons.done_outlined : Icons.add,
          ),
        ),
      );
    }

    Widget buildMoreButton(
        BuildContext context,
        WidgetRef ref,
        data,
        itemId,
        JfxLayout layout,
        ValueNotifier<bool> played,
        StreamController<List<BaseItemDto>> streamController) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(100.0),
        child: Material(
          child: PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0)),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (data.remoteTrailers.toList().isNotEmpty)
                PopupMenuItem<String>(
                  value: 'watch_trailer',
                  child: ListTile(
                    leading: const Icon(Icons.movie_outlined),
                    iconColor: Theme.of(context).colorScheme.primary,
                    title: Text(AppLocalizations.of(context)!.watchTrailer,
                        style: layout.text.bodyLarge),
                  ),
                ),
              PopupMenuItem<String>(
                value: 'mark_as_played',
                child: !data.userData!.played!
                    ? ListTile(
                        leading: const Icon(Icons.check),
                        iconColor: Theme.of(context).colorScheme.primary,
                        title: Text(AppLocalizations.of(context)!.markAsPlayed,
                            style: layout.text.bodyLarge),
                      )
                    : ListTile(
                        leading: const Icon(Icons.close),
                        iconColor: Theme.of(context).colorScheme.tertiary,
                        title: Text(
                            AppLocalizations.of(context)!.markAsUnplayed,
                            style: layout.text.bodyLarge),
                      ),
              ),
            ],
            onSelected: (String value) async {
              if (value == 'watch_trailer') {
                // open external youtube link
                if (!await launchUrl(
                      Uri.parse(data.remoteTrailers!.first.url!),
                    ) &&
                    context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        AppLocalizations.of(context)!.couldNotOpenTrailer,
                        style: layout.text.bodyLarge!
                            .copyWith(color: layout.color.onPrimary)),
                    duration: const Duration(seconds: 1),
                  ));
                }
              } else if (value == 'mark_as_played') {
                await ref.read(apiProvider).markAsPlayed(
                    itemId: itemId, played: !data.userData!.played!);
                played.value = !data.userData!.played!; // toggle value
                streamController
                    .add(await ref.read(apiProvider).getEpisodes(itemId));
              }
            },
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100.0),
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.05),
              ),
              child: Icon(
                Icons.more_horiz_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        data.mediaSources != null && data.mediaSources!.length > 1
            ? buildAdditionalVersionsButton(
                context, data, layout, playButtonHovered)
            : buildPlayButton(context, ref, data, layout),
        const SizedBox(width: 8.0),
        buildFavoriteButton(context, ref, itemId, layout, onWatchlist),
        if (data.type != BaseItemKind.series) const SizedBox(width: 8.0),
        if (data.type != BaseItemKind.series)
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100.0),
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: RoundedDownloadButton(itemId: itemId, data: data),
          ),
        const SizedBox(width: 8.0),
        buildMoreButton(context, ref, data, itemId, layout, markedAsPlayed,
            streamController),
      ],
    );
  }
}
