import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/item_carousel.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/navigation/app_router.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:tentacle/tentacle.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';

class RecommendationCarousels extends HookConsumerWidget {
  const RecommendationCarousels({
    super.key,
  });

  String buildTitleString(RecommendationDto recommendation) {
    String title = recommendation.baselineItemName!;
    switch (recommendation.recommendationType) {
      case RecommendationType.similarToRecentlyPlayed:
        return AppLocalizations.of(navigatorKey.currentContext!)!
            .becauseYouWatched(title);
      case RecommendationType.similarToLikedItem:
        return AppLocalizations.of(navigatorKey.currentContext!)!
            .becauseYouLiked(title);
      case RecommendationType.hasActorFromRecentlyPlayed ||
            RecommendationType.hasLikedActor:
        return AppLocalizations.of(navigatorKey.currentContext!)!
            .starring(title);
      case RecommendationType.hasDirectorFromRecentlyPlayed ||
            RecommendationType.hasLikedDirector:
        return AppLocalizations.of(navigatorKey.currentContext!)!
            .directedBy(title);
      default:
        return AppLocalizations.of(navigatorKey.currentContext!)!
            .recommendedForYou;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(apiProvider).getRecommendations(),
      builder: (context, snapshot) {
        List<RecommendationDto> data = [];
        if (snapshot.hasData) {
          data = snapshot.data as List<RecommendationDto>;
          // Filter out "similar to" recommendations to avoid duplicates with home screen
          data = data
              .where((rec) =>
                  rec.recommendationType !=
                      RecommendationType.similarToRecentlyPlayed &&
                  rec.recommendationType != RecommendationType.similarToLikedItem)
              .toList();

          return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                if (data[index].items!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 10.0),
                  child: ItemCarousel(
                    imageList: data[index].items!.map((e) => e.id!).toList(),
                    titleList: data[index].items!.map((e) => e.name!).toList(),
                    subtitleList: data[index]
                        .items!
                        .map((e) => e.productionYear.toString())
                        .toList(),
                    title: buildTitleString(data[index]),
                    onTap: (carouselIndex) {
                      context.pushNamed(ScreenPaths.home + ScreenPaths.detail,
                          queryParameters: {
                            "id": data[index].items![carouselIndex].id!,
                          });
                    },
                  ),
                );
              });
        }
        return const SizedBox.shrink();
      },
    );
  }
}
