import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/item_carousel.dart';
import 'package:jellyflix/models/poster_type.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:openapi/openapi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState<String?>(null);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                height: 40,
                child: SearchBar(
                  hintText: AppLocalizations.of(context)!.search,
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
              const SizedBox(
                height: 20,
              ),
              Expanded(
                child: (searchQuery.value ?? "").isEmpty
                    ? Center(
                        child: Text(
                            AppLocalizations.of(context)!.startTypingSearch))
                    : SingleChildScrollView(
                        child: FutureBuilder(
                          future: ref
                              .read(apiProvider)
                              .getFilterItems(searchTerm: searchQuery.value),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              if (snapshot.data!.isEmpty) {
                                return Center(
                                    child: Text(AppLocalizations.of(context)!
                                        .noResultsFound));
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
                                          blurHashList: movieList.map((e) {
                                            return e.imageBlurHashes?.primary
                                                ?.values.first;
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
                                          title: AppLocalizations.of(context)!
                                              .movies,
                                        ),
                                  seriesList.isEmpty
                                      ? const SizedBox()
                                      : ItemCarousel(
                                          imageList: seriesList.map((e) {
                                            return e.id!;
                                          }).toList(),
                                          blurHashList: seriesList.map((e) {
                                            return e.imageBlurHashes?.primary
                                                ?.values.first;
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
                                          title: AppLocalizations.of(context)!
                                              .series,
                                        ),
                                  episodeList.isEmpty
                                      ? const SizedBox()
                                      : ItemCarousel(
                                          posterType: PosterType.horizontal,
                                          imageList: episodeList.map((e) {
                                            return e.id!;
                                          }).toList(),
                                          blurHashList: episodeList.map((e) {
                                            return e.imageBlurHashes?.primary
                                                ?.values.first;
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
                                          title: AppLocalizations.of(context)!
                                              .episodes,
                                        ),
                                  collectionList.isEmpty
                                      ? const SizedBox()
                                      : ItemCarousel(
                                          imageList: collectionList.map((e) {
                                            return e.id!;
                                          }).toList(),
                                          blurHashList: collectionList.map((e) {
                                            return e.imageBlurHashes?.primary
                                                ?.values.first;
                                          }).toList(),
                                          titleList: collectionList.map((e) {
                                            return e.name!;
                                          }).toList(),
                                          onTap: (index) {
                                            context.push(Uri(
                                                path: ScreenPaths.detail,
                                                queryParameters: {
                                                  "id":
                                                      collectionList[index].id!,
                                                  "selectedIndex": "1",
                                                }).toString());
                                          },
                                          title: AppLocalizations.of(context)!
                                              .collections,
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
      ),
    );
  }
}
