import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/jellyfin_image.dart';
import 'package:jellyflix/components/jfx_text_theme.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:tentacle/tentacle.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ImageBannerInnerPortrait extends HookConsumerWidget {
  final List<BaseItemDto> items;
  final double? height;
  final Function(BaseItemDto) onPressedPlay;
  final PageController controller;
  final Function(int) setCurrentPageCallback;
  final int currentPage;
  final bool playButtonPressed;

  const ImageBannerInnerPortrait({
    super.key,
    required this.items,
    required this.onPressedPlay,
    this.height = 600,
    required this.controller,
    required this.setCurrentPageCallback,
    required this.currentPage,
    required this.playButtonPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: controller,
            itemCount: items.length,
            onPageChanged: (value) {
              setCurrentPageCallback(value);
            },
            itemBuilder: (context, index) {
              // check if backdrop exists else use primary image
              return Stack(children: [
                JellyfinImage(
                    borderRadius: BorderRadius.zero,
                    id: items[index].id!,
                    type: items[index].backdropImageTags!.isNotEmpty
                        ? ImageType.backdrop
                        : ImageType.primary),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color.fromARGB(30, 0, 0, 0),
                        Theme.of(context).colorScheme.surface
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 40),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[index].name!,
                          style: Theme.of(context).textTheme.headlineSmall,
                          maxLines: 2,
                        ),
                        Text(
                            items[index].productionYear == null
                                ? ""
                                : items[index].productionYear.toString(),
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: Text(items[index].overview ?? "",
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                                onPressed: () {
                                  BaseItemDto item = items[index];
                                  onPressedPlay(item);
                                },
                                label: Text(
                                    style: JfxTextTheme.scalingTheme(context)
                                        .bodyLarge!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                    AppLocalizations.of(context)!.play),
                                icon: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  child: playButtonPressed
                                      ? const SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(),
                                        )
                                      : const SizedBox(
                                          width: 10,
                                          child:
                                              Icon(Icons.play_arrow_rounded)),
                                )),
                            const SizedBox(
                              width: 10,
                            ),
                            TextButton(
                                onPressed: () {
                                  context.push(Uri(
                                      path: ScreenPaths.detail,
                                      queryParameters: {
                                        "id": items[index].id!,
                                      }).toString());
                                },
                                child: Text(
                                    style: JfxTextTheme.scalingTheme(context)
                                        .bodyLarge!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                    AppLocalizations.of(context)!.moreInfo)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: DotsIndicator(
            dotsCount: items.length,
            position: currentPage,
            decorator: DotsDecorator(
              activeColor: Theme.of(context).buttonTheme.colorScheme!.primary,
              activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0)),
              activeSize: const Size(40.0, 7.0),
              size: const Size(20, 7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0)),
            ),
            onTap: (position) {
              controller.animateToPage(position,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeIn);
            },
          ),
        ),
      ],
    );
  }
}
