import 'package:go_router/go_router.dart';
import 'package:jellyflix/components/future_item_carousel.dart';
import 'package:jellyflix/components/genre_banner.dart';
import 'package:jellyflix/components/paginated_item_carousel.dart';
import 'package:jellyflix/components/image_banner.dart';
import 'package:jellyflix/components/playback_progress_overlay.dart';
import 'package:jellyflix/components/recommendation_carousels.dart';
import 'package:jellyflix/models/poster_type.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/models/skeleton_item.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tentacle/tentacle.dart';
import 'package:jellyflix/providers/database_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
                future: ref.read(apiProvider).getHeaderRecommendation(),
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
                    if (items.length > 7) {
                      items = items.sublist(0, 7);
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: PaginatedItemCarousel(
                future: (startIndex, limit) =>
                    ref.read(apiProvider).continueWatchingAndNextUp(),
                onTap: (index, id) {
                  context.push(Uri(path: ScreenPaths.detail, queryParameters: {
                    "id": id,
                  }).toString());
                },
                imageMapping: (e) => e.id!,
                blurHashMapping: (e) =>
                    e.imageBlurHashes?.primary?.values.first,
                titleMapping: (e) => e.name!,
                subtitleMapping: (e) =>
                    e.productionYear == null ? "" : e.productionYear.toString(),
                title: AppLocalizations.of(context)!.continueWatching,
                overlay: (int index, BaseItemDto element) =>
                    PlaybackProgressOverlay(
                  progress: element.userData?.playedPercentage != null
                      ? element.userData!.playedPercentage! / 100
                      : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: PaginatedItemCarousel(
                pageSize: 20,
                future: (startIndex, limit) => ref
                    .read(apiProvider)
                    .getFilterItems(
                        sortBy: ["DateCreated"],
                        sortOrder: [SortOrder.descending],
                        includeItemTypes: [BaseItemKind.movie],
                        startIndex: startIndex,
                        limit: limit),
                onTap: (index, id) {
                  context.push(Uri(path: ScreenPaths.detail, queryParameters: {
                    "id": id,
                  }).toString());
                },
                title: AppLocalizations.of(context)!.recentlyAddedMovies,
                imageMapping: (e) => e.id!,
                blurHashMapping: (e) =>
                    e.imageBlurHashes?.primary?.values.first,
                titleMapping: (e) => e.name!,
                subtitleMapping: (e) => e.productionYear.toString(),
                posterType: PosterType.vertical,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: PaginatedItemCarousel(
                pageSize: 20,
                future: (startIndex, limit) => ref
                    .read(apiProvider)
                    .getFilterItems(
                        sortBy: ["DateCreated"],
                        sortOrder: [SortOrder.descending],
                        includeItemTypes: [BaseItemKind.series],
                        startIndex: startIndex,
                        limit: limit),
                onTap: (index, id) {
                  context.push(Uri(path: ScreenPaths.detail, queryParameters: {
                    "id": id,
                  }).toString());
                },
                title: AppLocalizations.of(context)!.recentlyAddedShows,
                imageMapping: (e) => e.id!,
                blurHashMapping: (e) =>
                    e.imageBlurHashes?.primary?.values.first,
                titleMapping: (e) => e.name!,
                subtitleMapping: (e) => e.productionYear.toString(),
                posterType: PosterType.vertical,
              ),
            ),
            const GenreBanner(),
            if (ref
                    .read(databaseProvider("settings"))
                    .get("disableWatchlist") !=
                true)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: PaginatedItemCarousel(
                  titleMapping: (e) => e.name!,
                  subtitleMapping: (e) => e.productionYear.toString(),
                  imageMapping: (e) => e.id!,
                  blurHashMapping: (e) =>
                      e.imageBlurHashes?.primary?.values.first,
                  future: (startIndex, limit) =>
                      ref.read(apiProvider).getWatchlist(),
                  title: AppLocalizations.of(context)!.yourWatchlist,
                  onTap: (index, id) {
                    context
                        .push(Uri(path: ScreenPaths.detail, queryParameters: {
                      "id": id,
                    }).toString());
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: FutureItemCarousel(
                onTap: (index, id) {
                  context.push(Uri(path: ScreenPaths.detail, queryParameters: {
                    "id": id,
                  }).toString());
                },
                titleMapping: (e) => e.name!,
                imageMapping: (e) => e.id!,
                blurHashMapping: (e) =>
                    e.imageBlurHashes?.primary?.values.first,
                future: ref.read(apiProvider).getTopTenPopular(),
                subtitleMapping: (e) => e.productionYear.toString(),
                title: AppLocalizations.of(context)!.top10inYourLibrary,
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
                      child: Center(
                          child: Text(
                              AppLocalizations.of(context)!.top10(index + 1)))),
                )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: PaginatedItemCarousel(
                title: AppLocalizations.of(context)!.similarToWatchHistory,
                titleMapping: (e) => e.name!,
                subtitleMapping: (e) => e.productionYear.toString(),
                imageMapping: (e) => e.id!,
                blurHashMapping: (e) =>
                    e.imageBlurHashes?.primary?.values.first,
                future: (startIndex, limit) =>
                    ref.read(apiProvider).similarItemsByLastWatched(),
                onTap: (index, id) {
                  context.push(Uri(path: ScreenPaths.detail, queryParameters: {
                    "id": id,
                  }).toString());
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: PaginatedItemCarousel(
                title: AppLocalizations.of(context)!.highesRatedMovies,
                titleMapping: (e) => e.name!,
                subtitleMapping: (e) => e.productionYear.toString(),
                imageMapping: (e) => e.id!,
                blurHashMapping: (e) =>
                    e.imageBlurHashes?.primary?.values.first,
                future: (startIndex, limit) =>
                    ref.read(apiProvider).getFilterItems(
                        sortBy: ["Random"],
                        minCommunityRating: 7.5,
                        includeItemTypes: [BaseItemKind.movie],
                        //filters: [ItemFilter.isUnplayed],
                        startIndex: startIndex,
                        limit: limit),
                onTap: (index, id) {
                  context.push(Uri(path: ScreenPaths.detail, queryParameters: {
                    "id": id,
                  }).toString());
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: PaginatedItemCarousel(
                title: AppLocalizations.of(context)!.highestRatedShows,
                titleMapping: (e) => e.name!,
                subtitleMapping: (e) => e.productionYear.toString(),
                imageMapping: (e) => e.id!,
                blurHashMapping: (e) =>
                    e.imageBlurHashes?.primary?.values.first,
                future: (startIndex, limit) => ref
                    .read(apiProvider)
                    .getFilterItems(
                        sortBy: ["Random"],
                        minCommunityRating: 7.5,
                        includeItemTypes: [BaseItemKind.series],
                        startIndex: startIndex,
                        limit: limit),
                onTap: (index, id) {
                  context.push(Uri(path: ScreenPaths.detail, queryParameters: {
                    "id": id,
                  }).toString());
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: PaginatedItemCarousel(
                title: AppLocalizations.of(context)!.moviesMaybeMissed,
                titleMapping: (e) => e.name!,
                subtitleMapping: (e) => e.productionYear.toString(),
                imageMapping: (e) => e.id!,
                blurHashMapping: (e) =>
                    e.imageBlurHashes?.primary?.values.first,
                future: (startIndex, limit) => ref
                    .read(apiProvider)
                    .getFilterItems(
                        sortBy: ["Random"],
                        sortOrder: [SortOrder.descending],
                        includeItemTypes: [BaseItemKind.movie],
                        filters: [ItemFilter.isUnplayed],
                        startIndex: startIndex,
                        limit: limit),
                onTap: (index, id) {
                  context.push(Uri(path: ScreenPaths.detail, queryParameters: {
                    "id": id,
                  }).toString());
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: PaginatedItemCarousel(
                title: AppLocalizations.of(context)!.showsMaybeMissed,
                titleMapping: (e) => e.name!,
                subtitleMapping: (e) => e.productionYear.toString(),
                imageMapping: (e) => e.id!,
                blurHashMapping: (e) =>
                    e.imageBlurHashes?.primary?.values.first,
                future: (startIndex, limit) => ref
                    .read(apiProvider)
                    .getFilterItems(
                        sortBy: ["Random"],
                        sortOrder: [SortOrder.descending],
                        includeItemTypes: [BaseItemKind.series],
                        filters: [ItemFilter.isUnplayed],
                        startIndex: startIndex,
                        limit: limit),
                onTap: (index, id) {
                  context.push(Uri(path: ScreenPaths.detail, queryParameters: {
                    "id": id,
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
