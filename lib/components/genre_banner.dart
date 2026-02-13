import 'package:flutter/material.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/item_carousel_label.dart';
import 'package:jellyflix/components/jellyfin_image.dart';
import 'package:jellyflix/components/jfx_text_theme.dart';
import 'package:jellyflix/models/gradients.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:tentacle/tentacle.dart';

class GenreBanner extends HookConsumerWidget {
  const GenreBanner({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController(viewportFraction: 0.95);

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: FutureBuilder(
          future: ref.read(apiProvider).getGenres(includeItemTypes: [
            BaseItemKind.movie,
            BaseItemKind.series,
            BaseItemKind.boxSet
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            snapshot.data!.shuffle();
            return Column(
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    child: ItemCarouselLabel(
                        title: AppLocalizations.of(context)!.genres,
                        scrollController: pageController,
                        offsetWidth: MediaQuery.of(context).size.width * 0.9)),
                SizedBox(
                  height: MediaQuery.of(context).size.width >= 640 ? 250 : 150,
                  child: PageView.builder(
                    controller: pageController,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () {
                            context.push(
                                "${ScreenPaths.library}?genreFilter=${snapshot.data![index].id}");
                          },
                          child: Stack(
                            children: [
                              Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: FutureBuilder(
                                    future: ref
                                        .read(apiProvider)
                                        .getFilterItems(
                                            genreIds: [snapshot.data![index]],
                                            limit: 1),
                                    builder: (context, itemData) {
                                      if (!itemData.hasData ||
                                          itemData.data!.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      var imageType = ImageType.backdrop;
                                      if ((itemData.data![0].imageTags
                                                  ?.containsKey("Backdrop") ??
                                              false) ==
                                          false) {
                                        imageType = ImageType.primary;
                                      }

                                      return JellyfinImage(
                                          id: itemData.data![0].id!,
                                          type: imageType,
                                          blurHash: itemData
                                              .data![0]
                                              .imageBlurHashes
                                              ?.backdrop
                                              ?.values
                                              .first);
                                    },
                                  )),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: Gradients.getGradient(index),
                                    stops: const [0, 0.5, 0.9],
                                    begin: Alignment.bottomRight,
                                    end: Alignment.topLeft,
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                              ),
                              Center(
                                child: Text(snapshot.data![index].name!,
                                    style: JfxTextTheme.scalingTheme(context)
                                        .headlineSmall!
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                        )),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                    itemCount: snapshot.data?.length ?? 0,
                    scrollDirection: Axis.horizontal,
                  ),
                ),
              ],
            );
          },
        ));
  }
}
