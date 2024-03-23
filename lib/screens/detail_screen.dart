import 'dart:async';
import 'dart:ui';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:jellyflix/components/rounded_download_button.dart';
import 'package:openapi/openapi.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';

import 'package:jellyflix/components/description_text.dart';
import 'package:jellyflix/components/episode_list.dart';
import 'package:jellyflix/components/item_information_details.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/models/skeleton_item.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/components/future_item_carousel.dart';
import 'package:jellyflix/components/item_carousel.dart';

class DetailScreen extends HookConsumerWidget {
  final String itemId;

  const DetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onWatchlist = useState(false);
    final ValueNotifier<bool?> markedAsPlayed = useState(null);
    final StreamController<List<BaseItemDto>> episodeStreamController =
        useStreamController();
    final playButtonHovered = useState(false);

    final scrollController = useScrollController();
    final appBarColorTransaparent = useState(true);

    useEffect(() {
      listener() {
        if (scrollController.position.pixels > 0) {
          appBarColorTransaparent.value = false;
        } else {
          appBarColorTransaparent.value = true;
        }
      }

      scrollController.addListener(listener);
      return () {
        return scrollController.removeListener(listener);
      };
    }, [scrollController]);

    ref.read(apiProvider).getWatchlist().then((value) {
      onWatchlist.value =
          value.where((element) => element.id == itemId).isNotEmpty;
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBarColorTransaparent.value
          ? AppBar(
              backgroundColor: Colors.transparent,
            )
          : PreferredSize(
              preferredSize: const Size(
                double.infinity,
                56.0,
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: AppBar(
                    elevation: 0.0,
                    backgroundColor: Colors.black.withOpacity(0.2),
                  ),
                ),
              ),
            ),
      body: FutureBuilder(
          future: ref.read(apiProvider).getItemDetails(itemId),
          builder: (context, AsyncSnapshot<BaseItemDto> snapshot) {
            BaseItemDto data = SkeletonItem.baseItemDto;
            if (snapshot.hasError) {
              return Center(
                child: Text(
                    AppLocalizations.of(context)!.quickConnectErrorUnknown),
              );
            } else if (snapshot.hasData) {
              data = snapshot.data!;
              if (data.type == BaseItemKind.series) {
                ref.read(apiProvider).getEpisodes(itemId).then((value) {
                  episodeStreamController.add(value);
                });
              }

              return Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 250 + MediaQuery.of(context).padding.top,
                        child: Stack(
                          children: [
                            Stack(
                              children: [
                                ref.read(apiProvider).getImage(
                                    borderRadius: BorderRadius.zero,
                                    id: data.type == BaseItemKind.episode
                                        ? data.seriesId!
                                        : itemId,
                                    type: ImageType.backdrop,
                                    blurHash: data
                                        .imageBlurHashes?.backdrop?[itemId]),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color.fromARGB(100, 0, 0, 0),
                                        Theme.of(context).colorScheme.surface
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).padding.top +
                                              17,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 8.0, left: 8.0, right: 8.0),
                                      child: Material(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        elevation: 10.0,
                                        child: Container(
                                          width: 150.0,
                                          height: 3 / 2 * 150.0,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: ref.read(apiProvider).getImage(
                                              id: itemId,
                                              type: ImageType.primary,
                                              blurHash: data.imageBlurHashes
                                                  ?.primary?[itemId]),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment
                                        .end, // Align text to the bottom
                                    children: [
                                      Text(
                                        data.name ?? "",
                                        style: const TextStyle(
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Row(
                                        children: [
                                          Text(
                                            data.premiereDate == null
                                                ? AppLocalizations.of(context)!
                                                    .na
                                                : data.premiereDate!.year
                                                    .toString(),
                                            style: const TextStyle(
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          const SizedBox(width: 16.0),
                                          Container(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 0.7,
                                                )),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(3.0),
                                              child: Text(
                                                data.officialRating ??
                                                    AppLocalizations.of(
                                                            context)!
                                                        .na,
                                                style: const TextStyle(
                                                  fontSize: 10.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4.0),
                                      Row(
                                        children: [
                                          data.communityRating == null
                                              ? const SizedBox()
                                              : Row(
                                                  children: [
                                                    const Text(
                                                      "⭐",
                                                      style: TextStyle(
                                                          fontSize: 20),
                                                    ),
                                                    const SizedBox(width: 4.0),
                                                    Text(
                                                      (data.communityRating ==
                                                              null)
                                                          ? AppLocalizations.of(
                                                                  context)!
                                                              .na
                                                          : data
                                                              .communityRating!
                                                              .roundToDouble()
                                                              .toString(),
                                                      style: const TextStyle(
                                                        fontSize: 12.0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          const SizedBox(width: 16.0),
                                          data.criticRating == null
                                              ? const SizedBox()
                                              : Row(
                                                  children: [
                                                    const Text(
                                                      "🍅",
                                                      style: TextStyle(
                                                          fontSize: 20),
                                                    ),
                                                    const SizedBox(width: 4.0),
                                                    Text(
                                                      data.criticRating!
                                                          .round()
                                                          .toString(),
                                                      style: const TextStyle(
                                                        fontSize: 12.0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 15.0),
                        child: Row(
                          children: [
                            data.mediaSources != null &&
                                    data.mediaSources!.length > 1
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(100.0),
                                    child: Material(
                                      child: PopupMenuButton(
                                        itemBuilder: (BuildContext context) {
                                          List<PopupMenuEntry> popUpItems = [];
                                          for (var element
                                              in data.mediaSources!) {
                                            popUpItems.add(PopupMenuItem(
                                              value: element.id,
                                              child: Text(element.name!),
                                            ));
                                          }
                                          return popUpItems;
                                        },
                                        tooltip: "",
                                        onSelected: (value) async {
                                          await goToPlayerScreen(
                                              ref,
                                              value,
                                              data.userData!
                                                  .playbackPositionTicks!,
                                              context);
                                        },
                                        child: MouseRegion(
                                          onEnter: (event) {
                                            playButtonHovered.value = true;
                                          },
                                          onExit: (event) {
                                            playButtonHovered.value = false;
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(100.0),
                                              color: playButtonHovered.value
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.9)
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15.0,
                                                      vertical: 5.0),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.play_arrow,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary,
                                                  ),
                                                  const SizedBox(width: 8.0),
                                                  Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .play,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () async {
                                      String itemId;
                                      int playbackStartTicks = 0;

                                      if (data.type == BaseItemKind.series) {
                                        List<BaseItemDto> continueWatching =
                                            await ref
                                                .read(apiProvider)
                                                .getContinueWatching(
                                                    parentId: data.id!);
                                        if (continueWatching.isNotEmpty) {
                                          itemId = continueWatching.first.id!;
                                          playbackStartTicks = continueWatching
                                              .first
                                              .userData!
                                              .playbackPositionTicks!;
                                        } else {
                                          List<BaseItemDto> result = await ref
                                              .read(apiProvider)
                                              .getNextUpEpisode(
                                                  seriesId: data.id!);
                                          if (result.isNotEmpty) {
                                            itemId = result.first.id!;
                                          } else {
                                            List<BaseItemDto> episodes =
                                                await ref
                                                    .read(apiProvider)
                                                    .getEpisodes(data.id!);
                                            itemId = episodes.first.id!;
                                          }
                                        }
                                      } else {
                                        itemId = data.mediaSources!.first.id!;
                                        playbackStartTicks = data
                                            .userData!.playbackPositionTicks!;
                                      }
                                      if (context.mounted) {
                                        await goToPlayerScreen(ref, itemId,
                                            playbackStartTicks, context);
                                      }
                                    },
                                    icon: const Icon(Icons.play_arrow),
                                    label: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Text(
                                          AppLocalizations.of(context)!.play),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  ),
                            const SizedBox(width: 8.0),
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100.0),
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  await ref.read(apiProvider).updateWatchlist(
                                      itemId, !onWatchlist.value);
                                  onWatchlist.value = !onWatchlist.value;

                                  if (context.mounted) {
                                    // show snackbar
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(onWatchlist.value
                                          ? AppLocalizations.of(context)!
                                              .addedToWatchlist
                                          : AppLocalizations.of(context)!
                                              .removedFromWatchlist),
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
                                  onWatchlist.value
                                      ? Icons.done_outlined
                                      : Icons.add,
                                ),
                              ),
                            ),
                            if (data.type != BaseItemKind.series)
                              const SizedBox(width: 8.0),
                            if (data.type != BaseItemKind.series)
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100.0),
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                child: RoundedDownloadButton(
                                    itemId: itemId, data: data),
                              ),
                            const SizedBox(width: 8.0),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100.0),
                              child: Material(
                                child: PopupMenuButton<String>(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(15.0)),
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                    if (data.remoteTrailers == null)
                                      PopupMenuItem<String>(
                                        value: 'watch_trailer',
                                        child: ListTile(
                                          leading:
                                              const Icon(Icons.movie_outlined),
                                          iconColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          title: Text(
                                              AppLocalizations.of(context)!
                                                  .watchTrailer),
                                        ),
                                      ),
                                    PopupMenuItem<String>(
                                      value: 'mark_as_played',
                                      child: !(markedAsPlayed.value ??
                                              data.userData!.played!)
                                          ? ListTile(
                                              leading: const Icon(Icons.check),
                                              iconColor: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              title: Text(
                                                AppLocalizations.of(context)!
                                                    .markAsPlayed,
                                              ),
                                            )
                                          : ListTile(
                                              leading: const Icon(Icons.close),
                                              iconColor: Theme.of(context)
                                                  .colorScheme
                                                  .tertiary,
                                              title: Text(
                                                AppLocalizations.of(context)!
                                                    .markAsUnplayed,
                                              ),
                                            ),
                                    ),
                                  ],
                                  onSelected: (String value) async {
                                    if (value == 'watch_trailer') {
                                      // open external youtube link
                                      if (!await launchUrl(
                                            Uri.parse(data
                                                .remoteTrailers!.first.url!),
                                          ) &&
                                          context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              AppLocalizations.of(context)!
                                                  .couldNotOpenTrailer),
                                          duration: const Duration(seconds: 1),
                                        ));
                                      }
                                    } else if (value == 'mark_as_played') {
                                      await ref.read(apiProvider).markAsPlayed(
                                          itemId: itemId,
                                          played: !(markedAsPlayed.value ??
                                              data.userData!.played!));
                                      markedAsPlayed.value =
                                          !(markedAsPlayed.value ??
                                              data.userData!
                                                  .played!); // toggle value
                                      episodeStreamController.add(await ref
                                          .read(apiProvider)
                                          .getEpisodes(itemId));
                                    }
                                  },
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(100.0),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.05),
                                    ),
                                    child: Icon(
                                      Icons.more_horiz_rounded,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 15.0),
                        child: DescriptionText(
                          text:
                              data.overview ?? AppLocalizations.of(context)!.na,
                        ),
                      ),

                      data.isFolder ?? false
                          ? EpisodeList(
                              episodeStreamController: episodeStreamController,
                              data: data,
                              markedAsPlayed: markedAsPlayed,
                              itemId: itemId)
                          : const SizedBox(),
                      data.people != null && data.people!.isNotEmpty
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15.0),
                              child: ItemCarousel(
                                title: AppLocalizations.of(context)!.cast,
                                titleList:
                                    data.people!.map((e) => e.name!).toList(),
                                imageList:
                                    data.people!.map((e) => e.id!).toList(),
                                subtitleList: data.people!
                                    .map((e) =>
                                        e.role ??
                                        AppLocalizations.of(context)!.na)
                                    .toList(),
                                onTap: (index) {
                                  context.push(Uri(
                                      path: ScreenPaths.detail,
                                      queryParameters: {
                                        "id": data.people![index].id!,
                                      }).toString());
                                },
                              ),
                            )
                          : const SizedBox(),
                      FutureItemCarousel(
                        future: ref.read(apiProvider).similarItems(itemId),
                        title: AppLocalizations.of(context)!.similar,
                        titleMapping: (e) => e.name!,
                        imageMapping: (e) => e.id!,
                        subtitleMapping: (e) => e.productionYear.toString(),
                        blurHashMapping: (e) =>
                            e.imageBlurHashes?.primary?[e.id!],
                        onTap: (index, id) {
                          context.push(
                              Uri(path: ScreenPaths.detail, queryParameters: {
                            "id": id,
                          }).toString());
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 10),
                        child: Text(AppLocalizations.of(context)!.details,
                            style: Theme.of(context).textTheme.headlineSmall),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ItemInformationDetails(item: data),
                      ),
                      // urls for review sites
                      if (data.externalUrls != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: SizedBox(
                            height: 20,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: data.externalUrls!.length,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () async {
                                    await launchUrl(Uri.parse(
                                        data.externalUrls![index].url!));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 5.0),
                                    child: Text(
                                      data.externalUrls![index].name!,
                                      style: const TextStyle(
                                          decoration: TextDecoration.underline),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
    );
  }

  Future<void> goToPlayerScreen(WidgetRef ref, String itemId,
      int playbackStartTicks, BuildContext context) async {
    var playbackInfo = await ref.read(apiProvider).getStreamUrlAndPlaybackInfo(
        itemId: itemId, startTimeTicks: playbackStartTicks);
    if (context.mounted) {
      context.push(
          Uri(path: ScreenPaths.player, queryParameters: {
            "startTimeTicks": playbackStartTicks.toString()
          }).toString(),
          extra: playbackInfo);
    }
  }
}
