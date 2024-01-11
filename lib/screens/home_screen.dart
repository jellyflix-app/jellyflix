import 'package:go_router/go_router.dart';
import 'package:jellyflix/components/future_item_carousel.dart';
import 'package:jellyflix/components/image_banner.dart';
import 'package:jellyflix/components/playback_progress_overlay.dart';
import 'package:jellyflix/components/recommendation_carousels.dart';
import 'package:jellyflix/components/responsive_navigation_bar.dart';
import 'package:jellyflix/models/poster_type.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/models/skeleton_item.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openapi/openapi.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveNavigationBar(
      selectedIndex: 0,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
                future: ref.read(apiProvider).getLatestItems("movies"),
                builder: (context, AsyncSnapshot<List<BaseItemDto>> snapshot) {
                  List<BaseItemDto> items = [
                    SkeletonItem.baseItemDto,
                    SkeletonItem.baseItemDto,
                    SkeletonItem.baseItemDto
                  ];
                  if (snapshot.hasData) {
                    if (snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    // filter where backdrop image is not null
                    items = snapshot.data!;
                    items.shuffle();
                    if (items.length > 5) {
                      items = items.sublist(0, 5);
                    }
                  }

                  return Skeletonizer(
                    enabled: !snapshot.hasData,
                    child: ImageBanner(
                      items: items,
                    ),
                  );
                }),
            const SizedBox(
              height: 20,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              //mainAxisSize: MainAxisSize.min,
              children: [
                // Continue carousel

                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20.0),
                  child: FutureItemCarousel(
                    future: ref.read(apiProvider).continueWatchingAndNextUp(),
                    onTap: (index, id) {
                      context
                          .push(Uri(path: ScreenPaths.detail, queryParameters: {
                        "id": id,
                        "selectedIndex": "0",
                      }).toString());
                    },
                    imageMapping: (e) => e.id!,
                    blurHashMapping: (e) =>
                        e.imageBlurHashes?.primary?.values.first,
                    titleMapping: (e) => e.name!,
                    subtitleMapping: (e) => e.productionYear == null
                        ? ""
                        : e.productionYear.toString(),
                    title: "Continue Watching",
                    overlay: (int index, BaseItemDto element) =>
                        PlaybackProgressOverlay(
                      progress: element.userData?.playedPercentage != null
                          ? element.userData!.playedPercentage! / 100
                          : null,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20.0),
                  child: FutureItemCarousel(
                    future: ref.read(apiProvider).getLatestItems("movies"),
                    onTap: (index, id) {
                      context
                          .push(Uri(path: ScreenPaths.detail, queryParameters: {
                        "id": id,
                        "selectedIndex": "0",
                      }).toString());
                    },
                    title: "Recently Added Movies",
                    imageMapping: (e) => e.id!,
                    blurHashMapping: (e) =>
                        e.imageBlurHashes?.primary?.values.first,
                    titleMapping: (e) => e.name!,
                    subtitleMapping: (e) => e.productionYear.toString(),
                    posterType: PosterType.vertical,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20.0),
                  child: FutureItemCarousel(
                    future: ref.read(apiProvider).getLatestItems("tvshows"),
                    onTap: (index, id) {
                      context
                          .push(Uri(path: ScreenPaths.detail, queryParameters: {
                        "id": id,
                        "selectedIndex": "0",
                      }).toString());
                    },
                    title: "Recently Added Shows",
                    imageMapping: (e) => e.id!,
                    blurHashMapping: (e) =>
                        e.imageBlurHashes?.primary?.values.first,
                    titleMapping: (e) => e.name!,
                    subtitleMapping: (e) => e.productionYear.toString(),
                    posterType: PosterType.vertical,
                  ),
                ),
              ],
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: FutureItemCarousel(
                titleMapping: (e) => e.name!,
                subtitleMapping: (e) => e.productionYear.toString(),
                imageMapping: (e) => e.id!,
                blurHashMapping: (e) =>
                    e.imageBlurHashes?.primary?.values.first,
                future: ref.read(apiProvider).getWatchlist(),
                title: "Your Watchlist",
                onTap: (index, id) {
                  context.push(Uri(path: ScreenPaths.detail, queryParameters: {
                    "id": id,
                    "selectedIndex": "0",
                  }).toString());
                },
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: FutureItemCarousel(
                onTap: (index, id) {
                  context.push(Uri(path: ScreenPaths.detail, queryParameters: {
                    "id": id,
                    "selectedIndex": "0",
                  }).toString());
                },
                titleMapping: (e) => e.name!,
                imageMapping: (e) => e.id!,
                blurHashMapping: (e) =>
                    e.imageBlurHashes?.primary?.values.first,
                future: ref.read(apiProvider).getTopTenPopular(),
                subtitleMapping: (e) => e.productionYear.toString(),
                title: "Top 10 in your library",
                overlay: (index, element) => Positioned(
                    child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Container(
                      height: 25,
                      width: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Theme.of(context)
                            .buttonTheme
                            .colorScheme!
                            .onPrimary,
                      ),
                      child: Center(child: Text("Top ${index + 1}"))),
                )),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: FutureItemCarousel(
                title: "Similar to your watch history",
                titleMapping: (e) => e.name!,
                subtitleMapping: (e) => e.productionYear.toString(),
                imageMapping: (e) => e.id!,
                blurHashMapping: (e) =>
                    e.imageBlurHashes?.primary?.values.first,
                future: ref.read(apiProvider).similarItemsByLastWatched(),
                onTap: (index, id) {
                  context.push(Uri(path: ScreenPaths.detail, queryParameters: {
                    "id": id,
                    "selectedIndex": "0",
                  }).toString());
                },
              ),
            ),
            const RecommendationCarousels(),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
