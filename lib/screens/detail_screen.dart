import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:jellyflix/components/item_carousel.dart';
import 'package:jellyflix/components/playback_progress_overlay.dart';
import 'package:jellyflix/components/responsive_navigation_bar.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/models/skeleton_item.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:openapi/openapi.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class DetailScreen extends HookConsumerWidget {
  final String itemId;
  final int selectedIndex;

  const DetailScreen(
      {super.key, required this.itemId, required this.selectedIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonSelection = useState(0);
    final onWatchlist = useState(false);

    ref.read(apiProvider).getWatchlist().then((value) {
      onWatchlist.value =
          value.where((element) => element.id == itemId).isNotEmpty;
    });

    return ResponsiveNavigationBar(
      selectedIndex: selectedIndex,
      body: FutureBuilder(
          future: ref.read(apiProvider).getItemDetails(itemId),
          builder: (context, AsyncSnapshot<BaseItemDto> snapshot) {
            BaseItemDto data = SkeletonItem.baseItemDto;
            if (snapshot.hasData) {
              data = snapshot.data!;
            }
            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                child: Skeletonizer(
                  enabled: !snapshot.hasData,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 300 + MediaQuery.of(context).padding.top,
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
                                        Theme.of(context).colorScheme.background
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
                                    Padding(
                                      padding: EdgeInsets.only(
                                          top: MediaQuery.of(context)
                                              .padding
                                              .top),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: BackButton(
                                            color: Colors.white,
                                            onPressed: () {
                                              context.pop();
                                            }),
                                      ),
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
                                                ? 'N/A'
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
                                                data.officialRating ?? 'N/A',
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
                                                          ? 'N/A'
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
                            ElevatedButton.icon(
                              onPressed: () async {
                                //TODO use next up episode if tvshow
                                String itemId;
                                int playbackStartTicks = 0;

                                if (data.type == BaseItemKind.series) {
                                  List<BaseItemDto> continueWatching = await ref
                                      .read(apiProvider)
                                      .getContinueWatching(parentId: data.id!);
                                  if (continueWatching.isNotEmpty) {
                                    itemId = continueWatching.first.id!;
                                    playbackStartTicks = continueWatching
                                        .first.userData!.playbackPositionTicks!;
                                  } else {
                                    List<BaseItemDto> result = await ref
                                        .read(apiProvider)
                                        .getNextUpEpisode(seriesId: data.id!);
                                    if (result.isNotEmpty) {
                                      itemId = result.first.id!;
                                    } else {
                                      List<BaseItemDto> episodes = await ref
                                          .read(apiProvider)
                                          .getEpisodes(data.id!);
                                      itemId = episodes.first.id!;
                                    }
                                  }
                                } else {
                                  itemId = data.mediaSources!.first.id!;
                                  playbackStartTicks =
                                      data.userData!.playbackPositionTicks!;
                                }
                                var playbackInfo = await ref
                                    .read(apiProvider)
                                    .getStreamUrlAndPlaybackInfo(
                                        itemId: itemId,
                                        startTimeTicks: playbackStartTicks);
                                if (context.mounted) {
                                  context.push(
                                      Uri(
                                          path: ScreenPaths.player,
                                          queryParameters: {
                                            "startTimeTicks":
                                                playbackStartTicks.toString()
                                          }).toString(),
                                      extra: playbackInfo);
                                }
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Play'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
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
                                          ? "Added to watchlist"
                                          : "Removed from watchlist"),
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
                            const SizedBox(width: 8.0),
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100.0),
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  // Add your watched button logic here
                                  showLicensePage(
                                      context: context,
                                      applicationName: "Jellyflix");
                                },
                                style: ElevatedButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    )),
                                child: const Icon(
                                  Icons.more_horiz_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 15.0),
                        child: Text(
                          data.overview ?? 'N/A',
                        ),
                      ),
                      // urls for review sites
                      if (data.externalUrls != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: SizedBox(
                            height: 20,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: data.externalUrls!.length,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () async {
                                    await launchUrl(Uri.dataFromString(
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
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Writers',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Directors',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('Genres',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(width: 20.0),
                            if (data.people != null)
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    // find every person that is a writer
                                    Text(data.people!
                                            .where((element) =>
                                                element.type == 'Writer')
                                            .isEmpty
                                        ? 'N/A'
                                        : data.people!
                                            .where((element) =>
                                                element.type == 'Writer')
                                            .map((e) => e.name!)
                                            .join(", ")),
                                    Text(data.people!
                                            .where((element) =>
                                                element.type == 'Director')
                                            .isEmpty
                                        ? 'N/A'
                                        : data.people!
                                            .where((element) =>
                                                element.type == 'Director')
                                            .map((e) => e.name!)
                                            .join(", ")),
                                    Text(
                                      data.genres!.isEmpty
                                          ? "N/A"
                                          : data.genres!.join(", "),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      data.isFolder ?? false
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5.0),
                                    child: Text("Episodes",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall),
                                  ),
                                  FutureBuilder(
                                    future: ref
                                        .read(apiProvider)
                                        .getEpisodes(itemId),
                                    builder: (context, snapshot) {
                                      var seasons = [];
                                      var seasonIds = [];
                                      var episodes = [];
                                      if (snapshot.hasData) {
                                        seasons = snapshot.data!
                                            .map((e) => e.seasonName)
                                            .toSet()
                                            .toList();

                                        // get season ids
                                        seasonIds = snapshot.data!
                                            .map((e) => e.seasonId)
                                            .toSet()
                                            .toList();
                                        // get episodes for season
                                        episodes = snapshot.data!
                                            .where((element) =>
                                                element.seasonId ==
                                                seasonIds[
                                                    seasonSelection.value])
                                            .toList();
                                      }
                                      return Skeletonizer(
                                        enabled: !snapshot.hasData,
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              height: 60,
                                              child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  shrinkWrap: true,
                                                  itemCount: seasons.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 5.0),
                                                      child: ChoiceChip(
                                                          selected:
                                                              seasonSelection
                                                                      .value ==
                                                                  index,
                                                          onSelected:
                                                              (selected) {
                                                            seasonSelection
                                                                .value = index;
                                                          },
                                                          label: Text(
                                                              seasons[index])),
                                                    );
                                                  }),
                                            ),
                                            ListView.builder(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: episodes.length,
                                              itemBuilder: (context, index) {
                                                BaseItemDto item =
                                                    episodes[index];
                                                return SizedBox(
                                                  height: 125,
                                                  child: InkWell(
                                                    onTap: () async {
                                                      var playbackInfo = await ref
                                                          .read(apiProvider)
                                                          .getStreamUrlAndPlaybackInfo(
                                                              itemId: item.id!);
                                                      if (context.mounted) {
                                                        context.push(
                                                            Uri(
                                                                path:
                                                                    ScreenPaths
                                                                        .player,
                                                                queryParameters: {
                                                                  "startTimeTicks": data
                                                                      .userData
                                                                      ?.playbackPositionTicks
                                                                      ?.toString()
                                                                }).toString(),
                                                            extra:
                                                                playbackInfo);
                                                      }
                                                    },
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical:
                                                                      20.0),
                                                          child: AspectRatio(
                                                            aspectRatio:
                                                                16 / 10,
                                                            child: Stack(
                                                              children: [
                                                                Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10.0),
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.5),
                                                                        spreadRadius:
                                                                            2,
                                                                        blurRadius:
                                                                            5,
                                                                        offset: const Offset(
                                                                            0,
                                                                            3),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  child: ref.read(apiProvider).getImage(
                                                                      id: item
                                                                          .id!,
                                                                      type: ImageType
                                                                          .primary,
                                                                      blurHash: item
                                                                          .imageBlurHashes
                                                                          ?.primary?[item.id!]),
                                                                ),
                                                                if (item.userData!
                                                                        .playedPercentage !=
                                                                    null)
                                                                  PlaybackProgressOverlay(
                                                                      progress: (item
                                                                              .userData!
                                                                              .playedPercentage! /
                                                                          100)),
                                                                if (item.userData!
                                                                        .played ==
                                                                    true)
                                                                  Positioned(
                                                                    bottom: 5.0,
                                                                    right: 5.0,
                                                                    child: Icon(
                                                                      Icons
                                                                          .check_circle_outline_rounded,
                                                                      size: 20,
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.8),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 20.0),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical:
                                                                      20.0),
                                                          child: SizedBox(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.5,
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  ("${item.indexNumber!}. ${item.name!}"),
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          16.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                                Text(item.runTimeTicks ==
                                                                        null
                                                                    ? "N/A"
                                                                    : "${(item.runTimeTicks! / 10000000 / 60).round()} min")
                                                              ],
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                      // } else {
                                      //   return const CircularProgressIndicator();
                                      // }
                                    },
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(),
                      data.people != null && data.people!.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 15.0),
                              child: ItemCarousel(
                                title: 'Cast',
                                titleList:
                                    data.people!.map((e) => e.name!).toList(),
                                imageList:
                                    data.people!.map((e) => e.id!).toList(),
                                subtitleList:
                                    data.people!.map((e) => e.role!).toList(),
                              ),
                            )
                          : const SizedBox(),
                    ],
                  ),
                ),
              ),
            );
            // } else {
            //   return const CircularProgressIndicator();
            // }
          }),
    );
  }
}
