import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/future_item_carousel.dart';
import 'package:jellyflix/components/jfx_text_theme.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:tentacle/tentacle.dart';
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
                            AppLocalizations.of(context)!.startTypingSearch,
                            style:
                                JfxTextTheme.scalingTheme(context).titleMedium))
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureItemCarousel(
                              title: AppLocalizations.of(context)!.movies,
                              titleMapping: (e) => e.name!,
                              imageMapping: (e) => e.id!,
                              blurHashMapping: (e) =>
                                  e.imageBlurHashes?.primary?.values.first,
                              future: ref.read(apiProvider).getFilterItems(
                                searchTerm: searchQuery.value,
                                includeItemTypes: [BaseItemKind.movie],
                              ),
                              onTap: (p0, p1) {
                                context.push(Uri(
                                    path: ScreenPaths.detail,
                                    queryParameters: {
                                      "id": p1,
                                    }).toString());
                              },
                            ),
                            FutureItemCarousel(
                                title: AppLocalizations.of(context)!.series,
                                titleMapping: (e) => e.name!,
                                imageMapping: (e) => e.id!,
                                blurHashMapping: (e) =>
                                    e.imageBlurHashes?.primary?.values.first,
                                future: ref.read(apiProvider).getFilterItems(
                                  searchTerm: searchQuery.value,
                                  includeItemTypes: [BaseItemKind.series],
                                ),
                                onTap: (p0, p1) {
                                  context.push(Uri(
                                      path: ScreenPaths.detail,
                                      queryParameters: {
                                        "id": p1,
                                      }).toString());
                                }),
                            FutureItemCarousel(
                                title: AppLocalizations.of(context)!.episodes,
                                titleMapping: (e) => e.name!,
                                imageMapping: (e) => e.id!,
                                blurHashMapping: (e) =>
                                    e.imageBlurHashes?.primary?.values.first,
                                future: ref.read(apiProvider).getFilterItems(
                                  searchTerm: searchQuery.value,
                                  includeItemTypes: [BaseItemKind.episode],
                                ),
                                onTap: (p0, p1) {
                                  context.push(Uri(
                                      path: ScreenPaths.detail,
                                      queryParameters: {
                                        "id": p1,
                                      }).toString());
                                }),
                            FutureItemCarousel(
                              title: AppLocalizations.of(context)!.collections,
                              titleMapping: (e) => e.name!,
                              imageMapping: (e) => e.id!,
                              blurHashMapping: (e) =>
                                  e.imageBlurHashes?.primary?.values.first,
                              future: ref.read(apiProvider).getFilterItems(
                                searchTerm: searchQuery.value,
                                includeItemTypes: [
                                  BaseItemKind.boxSet,
                                ],
                              ),
                              onTap: (p0, p1) {
                                context.push(Uri(
                                    path: ScreenPaths.detail,
                                    queryParameters: {
                                      "id": p1,
                                    }).toString());
                              },
                            ),
                            // FutureItemCarousel(
                            //     title: AppLocalizations.of(context)!.play,
                            //     titleMapping: (e) => e.name!,
                            //     imageMapping: (e) => e.id!,
                            //     blurHashMapping: (e) =>
                            //         e.imageBlurHashes?.primary?.values.first,
                            //     future: ref.read(apiProvider).getFilterItems(
                            //         searchTerm: searchQuery.value,
                            //         includeItemTypes: [BaseItemKind.playlist])),
                          ],
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
