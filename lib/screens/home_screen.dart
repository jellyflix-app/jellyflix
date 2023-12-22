import 'package:go_router/go_router.dart';
import 'package:jellyflix/components/future_item_carousel.dart';
import 'package:jellyflix/components/image_banner.dart';
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
                    // filter where backdrop image is not null
                    items = snapshot.data!;
                    items.shuffle();
                    items = items.sublist(0, 5);
                  }

                  return Skeletonizer(
                    enabled: !snapshot.hasData,
                    child: ImageBanner(
                      items: items,
                    ),
                  );
                }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                //mainAxisSize: MainAxisSize.min,
                children: [
                  // Continue carousel

                  FutureItemCarousel(
                      future: ref.read(apiProvider).getContinueWatching(),
                      onTap: (index, id) {
                        context.push(
                            Uri(path: ScreenPaths.detail, queryParameters: {
                          "id": id,
                          "selectedIndex": "0",
                        }).toString());
                      },
                      imageMapping: (e) => e.id!,
                      titleMapping: (e) => e.name!,
                      subtitleMapping: (e) => e.productionYear.toString(),
                      title: "Continue Watching"),

                  FutureItemCarousel(
                      future: ref.read(apiProvider).getLatestItems("movies"),
                      onTap: (index, id) {
                        context.push(
                            Uri(path: ScreenPaths.detail, queryParameters: {
                          "id": id,
                          "selectedIndex": "0",
                        }).toString());
                      },
                      title: "Recently Added Movies",
                      imageMapping: (e) => e.id!,
                      titleMapping: (e) => e.name!,
                      subtitleMapping: (e) => e.productionYear.toString(),
                      posterType: PosterType.vertical),

                  FutureItemCarousel(
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
                    titleMapping: (e) => e.name!,
                    subtitleMapping: (e) => e.productionYear.toString(),
                    posterType: PosterType.vertical,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
