import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/item_carousel_row.dart';
import 'package:jellyflix/models/gradients.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:openapi/openapi.dart';

class GenreBanner extends HookConsumerWidget {
  const GenreBanner({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = PageController(viewportFraction: 0.95);

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: FutureBuilder(
          future: ref.read(apiProvider).getGenres(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    child: ItemCarouselRow(
                        title: AppLocalizations.of(context)!.genres,
                        scrollController: pageController,
                        offsetWidth: MediaQuery.of(context).size.width * 0.9)),
                SizedBox(
                  height: 250,
                  child: PageView.builder(
                    controller: pageController,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () {
                            context.push(Uri(
                                path: ScreenPaths.library,
                                queryParameters: {
                                  "genreFilter": snapshot.data![index].id,
                                }).toString());
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
                                      if (!itemData.hasData) {
                                        return const SizedBox.shrink();
                                      }
                                      var imageType = ImageType.backdrop;
                                      if ((itemData.data![0].imageTags
                                                  ?.containsKey("Backdrop") ??
                                              false) ==
                                          false) {
                                        imageType = ImageType.primary;
                                      }

                                      return ref.read(apiProvider).getImage(
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
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ),
                              Center(
                                child: Text(snapshot.data![index].name!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium!
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
