import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/item_carousel.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:openapi/openapi.dart';

class RecommendationCarousels extends HookConsumerWidget {
  const RecommendationCarousels({
    super.key,
  });

  String buildTitleString(RecommendationDto recommendation) {
    String title = recommendation.baselineItemName!;
    switch (recommendation.recommendationType) {
      case RecommendationType.similarToRecentlyPlayed:
        return "Because you watched $title";
      case RecommendationType.similarToLikedItem:
        return "Because you liked $title";
      case RecommendationType.hasActorFromRecentlyPlayed ||
            RecommendationType.hasLikedActor:
        return "Starring $title";
      case RecommendationType.hasDirectorFromRecentlyPlayed ||
            RecommendationType.hasLikedDirector:
        return "Directed by $title";
      default:
        return "Recommended for you";
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
                  ),
                );
              });
        }
        return const SizedBox.shrink();
      },
    );
  }
}
