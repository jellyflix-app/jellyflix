import 'package:go_router/go_router.dart';
import 'package:jellyflix/components/image_banner.dart';
import 'package:jellyflix/components/item_carousel.dart';
import 'package:jellyflix/components/responsive_navigation_bar.dart';
import 'package:jellyflix/models/poster_type.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openapi/openapi.dart';

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
                  if (snapshot.hasData) {
                    // filter where backdrop image is not null
                    var items = snapshot.data!;
                    items.shuffle();
                    items = items.sublist(0, 5);
                    return ImageBanner(
                      items: items,
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                //mainAxisSize: MainAxisSize.min,
                children: [
                  // Continue carousel
                  FutureBuilder(
                      future: ref.read(apiProvider).getContinueWatching(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ItemCarousel(
                              onTap: (index) {
                                context.push(Uri(
                                    path: ScreenPaths.detail,
                                    queryParameters: {
                                      "id": snapshot.data!.items[index].id,
                                      "selectedIndex": "0",
                                    }).toString());
                              },
                              imageList: snapshot.data!.items.map((e) {
                                return e.id!;
                              }).toList(),
                              titleList: snapshot.data!.items.map((e) {
                                return e.name!;
                              }).toList(),
                              subtitleList: snapshot.data!.items.map((e) {
                                return e.productionYear.toString();
                              }).toList(),
                              title: "Continue Watching");
                        } else {
                          return const CircularProgressIndicator();
                        }
                      }),
                  FutureBuilder(
                      future: ref.read(apiProvider).getLatestItems("movies"),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ItemCarousel(
                              onTap: (index) {
                                context.push(Uri(
                                    path: ScreenPaths.detail,
                                    queryParameters: {
                                      "id": snapshot.data![index].id!,
                                      "selectedIndex": "0",
                                    }).toString());
                              },
                              imageList: snapshot.data!.map((e) {
                                return e.id!;
                              }).toList(),
                              titleList: snapshot.data!.map((e) {
                                return e.name!;
                              }).toList(),
                              title: "Recently Added Movies",
                              subtitleList: snapshot.data!.map((e) {
                                return e.productionYear.toString();
                              }).toList(),
                              posterType: PosterType.vertical);
                        } else {
                          return const CircularProgressIndicator();
                        }
                      }),
                  FutureBuilder(
                      future: ref.read(apiProvider).getLatestItems("tvshows"),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ItemCarousel(
                              onTap: (index) {
                                context.push(Uri(
                                    path: ScreenPaths.detail,
                                    queryParameters: {
                                      "id": snapshot.data![index].id!,
                                      "selectedIndex": "0",
                                    }).toString());
                              },
                              imageList: snapshot.data!.map((e) {
                                return e.id!;
                              }).toList(),
                              titleList: snapshot.data!.map((e) {
                                return e.name!;
                              }).toList(),
                              subtitleList: snapshot.data!.map((e) {
                                return e.productionYear.toString();
                              }).toList(),
                              title: "Recently Added Shows",
                              posterType: PosterType.vertical);
                        } else {
                          return const CircularProgressIndicator();
                        }
                      }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
