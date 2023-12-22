import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/item_carousel.dart';
import 'package:jellyflix/components/responsive_navigation_bar.dart';
import 'package:jellyflix/models/poster_type.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:openapi/openapi.dart';

class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState<String?>(null);

    return ResponsiveNavigationBar(
      selectedIndex: 1,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: SearchBar(
                  hintText: "Search",
                  leading: const Icon(Icons.search_rounded),
                  onChanged: (value) {
                    if (value != "") {
                      searchQuery.value = value;
                    } else {
                      searchQuery.value = null;
                    }
                  },
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: (searchQuery.value ?? "").isEmpty
                  ? const Center(child: Text("Start typing to search"))
                  : SingleChildScrollView(
                      child: FutureBuilder(
                        future: ref
                            .read(apiProvider)
                            .getFilterItems(searchTerm: searchQuery.value),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            if (snapshot.data!.isEmpty) {
                              return const Center(
                                  child: Text("No results found"));
                            }
                            List<BaseItemDto> movieList = snapshot.data!
                                .where((element) =>
                                    element.type == BaseItemKind.movie)
                                .toList();
                            List<BaseItemDto> seriesList = snapshot.data!
                                .where((element) =>
                                    element.type == BaseItemKind.series)
                                .toList();
                            List<BaseItemDto> episodeList = snapshot.data!
                                .where((element) =>
                                    element.type == BaseItemKind.episode)
                                .toList();
                            List<BaseItemDto> collectionList = snapshot.data!
                                .where((element) =>
                                    element.type == BaseItemKind.boxSet)
                                .toList();
                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                movieList.isEmpty
                                    ? const SizedBox()
                                    : ItemCarousel(
                                        imageList: movieList.map((e) {
                                          return e.id!;
                                        }).toList(),
                                        titleList: movieList.map((e) {
                                          return e.name!;
                                        }).toList(),
                                        onTap: (index) {
                                          context.push(Uri(
                                              path: ScreenPaths.detail,
                                              queryParameters: {
                                                "id": movieList[index].id!,
                                                "selectedIndex": "1",
                                              }).toString());
                                        },
                                        title: "Movies",
                                      ),
                                seriesList.isEmpty
                                    ? const SizedBox()
                                    : ItemCarousel(
                                        imageList: seriesList.map((e) {
                                          return e.id!;
                                        }).toList(),
                                        titleList: seriesList.map((e) {
                                          return e.name!;
                                        }).toList(),
                                        onTap: (index) {
                                          context.push(Uri(
                                              path: ScreenPaths.detail,
                                              queryParameters: {
                                                "id": seriesList[index].id!,
                                                "selectedIndex": "1",
                                              }).toString());
                                        },
                                        title: "Series",
                                      ),
                                episodeList.isEmpty
                                    ? const SizedBox()
                                    : ItemCarousel(
                                        posterType: PosterType.horizontal,
                                        imageList: episodeList.map((e) {
                                          return e.id!;
                                        }).toList(),
                                        titleList: episodeList.map((e) {
                                          return e.name!;
                                        }).toList(),
                                        onTap: (index) {
                                          context.push(Uri(
                                              path: ScreenPaths.detail,
                                              queryParameters: {
                                                "id": episodeList[index].id!,
                                                "selectedIndex": "1",
                                              }).toString());
                                        },
                                        title: "Episodes",
                                      ),
                                collectionList.isEmpty
                                    ? const SizedBox()
                                    : ItemCarousel(
                                        imageList: collectionList.map((e) {
                                          return e.id!;
                                        }).toList(),
                                        titleList: collectionList.map((e) {
                                          return e.name!;
                                        }).toList(),
                                        onTap: (index) {
                                          context.push(Uri(
                                              path: ScreenPaths.detail,
                                              queryParameters: {
                                                "id": collectionList[index].id!,
                                                "selectedIndex": "1",
                                              }).toString());
                                        },
                                        title: "Collections",
                                      ),
                              ],
                            );
                          } else {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
