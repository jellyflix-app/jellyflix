import 'package:flutter/material.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jellyflix/components/item_carousel_label.dart';
import 'package:jellyflix/components/jellyfin_image.dart';
import 'package:jellyflix/components/jfx_text_theme.dart';
import 'package:jellyflix/components/focus_border.dart';
import 'package:jellyflix/models/gradients.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';

import 'package:tentacle/tentacle.dart';

class GenreBanner extends ConsumerStatefulWidget {
  final bool requestInitialFocus;

  const GenreBanner({
    super.key,
    this.requestInitialFocus = false,
  });

  @override
  ConsumerState<GenreBanner> createState() => _GenreBannerState();
}

class _GenreBannerState extends ConsumerState<GenreBanner> {
  late final PageController pageController;
  final Map<int, List<FocusNode>> _focusNodesCache = {};

  @override
  void initState() {
    super.initState();
    pageController = PageController(viewportFraction: 0.95);
  }

  @override
  void dispose() {
    pageController.dispose();
    // Dispose all cached focus nodes
    for (var focusNodes in _focusNodesCache.values) {
      for (var node in focusNodes) {
        node.dispose();
      }
    }
    _focusNodesCache.clear();
    super.dispose();
  }

  List<FocusNode> _getFocusNodes(int count) {
    if (_focusNodesCache[count] == null) {
      _focusNodesCache[count] = List.generate(count, (_) => FocusNode());

      // Request initial focus if needed
      if (widget.requestInitialFocus && _focusNodesCache[count]!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNodesCache[count]![0].requestFocus();
        });
      }
    }
    return _focusNodesCache[count]!;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: FutureBuilder<List<BaseItemDto>>(
          future: ref.read(apiProvider).getGenres(includeItemTypes: [
            BaseItemKind.movie,
            BaseItemKind.series,
            BaseItemKind.boxSet
          ]),
          builder: (context, AsyncSnapshot<List<BaseItemDto>> snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            final genres = snapshot.data!;
            genres.shuffle();

            // Get or create focus nodes for this genre count
            final focusNodes = _getFocusNodes(genres.length);

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
                      final genreWidget = InkWell(
                        onTap: () {
                          context
                              .pushNamed(ScreenPaths.library, queryParameters: {
                            "genreFilter": genres[index].id,
                          });
                        },
                        child: Stack(
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: FutureBuilder(
                                  future: ref.read(apiProvider).getFilterItems(
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
                              child: Text(genres[index].name!,
                                  style: JfxTextTheme.scalingTheme(context)
                                      .headlineSmall!
                                      .copyWith(
                                        fontWeight: FontWeight.bold,
                                      )),
                            )
                          ],
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: index < focusNodes.length
                            ? Focus(
                                focusNode: focusNodes[index],
                                child: FocusBorder(
                                  focusNode: focusNodes[index],
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: genreWidget,
                                ),
                              )
                            : genreWidget,
                      );
                    },
                    itemCount: genres.length,
                    scrollDirection: Axis.horizontal,
                  ),
                ),
              ],
            );
          },
        ));
  }
}
