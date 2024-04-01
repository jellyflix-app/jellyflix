import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/global_state.dart';
import 'package:jellyflix/components/jellyfin_image.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:openapi/openapi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DesktopImageBanner extends StatefulHookConsumerWidget {
  final List<BaseItemDto> items;
  final Duration scrollDuration;
  final double? height;
  final Function(BaseItemDto) onPressedPlay;

  const DesktopImageBanner(
      {super.key,
      required this.items,
      required this.onPressedPlay,
      this.height = 600,
      this.scrollDuration = const Duration(seconds: 5)});

  @override
  DestkopImageBannerState createState() => DestkopImageBannerState();
}

class DestkopImageBannerState extends ConsumerState<DesktopImageBanner> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  RestartableTimer? _timer;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _timer = RestartableTimer(widget.scrollDuration, () {
      if (!_hovered && !ref.read(globalState.mediaPlaybackIsLoading)) {
        if (_currentPage < widget.items.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _controller.animateToPage(_currentPage,
            duration: const Duration(milliseconds: 350), curve: Curves.easeIn);
      }
      _timer?.reset();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _timer?.reset();
        setState(() {
          _hovered = true;
        });
      },
      onHover: (_) {
        _timer?.reset();
      },
      onExit: (_) {
        _timer?.reset();
        setState(() {
          _hovered = false;
        });
      },
      child: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.items.length,
              onPageChanged: (value) {
                setState(() {
                  _currentPage = value;
                });
              },
              itemBuilder: (context, index) {
                // check if backdrop exists else use primary image
                final isLoading = ref.watch(globalState.mediaPlaybackIsLoading);
                return Stack(children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: (MediaQuery.of(context).size.width * 0.6)
                          .roundToDouble(),
                      child: JellyfinImage(
                        borderRadius: BorderRadius.zero,
                        id: widget.items[index].id!,
                        type: widget.items[index].backdropImageTags!.isNotEmpty
                            ? ImageType.backdrop
                            : ImageType.primary,
                        blurHash:
                            widget.items[index].backdropImageTags!.isNotEmpty
                                ? widget.items[index].imageBlurHashes?.backdrop
                                    ?.values.first
                                : widget.items[index].imageBlurHashes?.primary
                                    ?.values.first,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: (MediaQuery.of(context).size.width * 0.6)
                          .roundToDouble(),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(0.1, 0),
                          end: Alignment.centerLeft,
                          colors: [
                            const Color.fromARGB(30, 0, 0, 0),
                            Theme.of(context).colorScheme.surface
                          ],
                        ),
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
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.items[index].name!,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                  maxLines: 2,
                                ),
                                Text(
                                    widget.items[index].productionYear
                                        .toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(widget.items[index].overview ?? "",
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                  onPressed: () {
                                    ref
                                        .read(globalState
                                            .mediaPlaybackIsLoading.notifier)
                                        .update((state) => true);
                                    BaseItemDto item = widget.items[index];
                                    widget.onPressedPlay(item);
                                  },
                                  label:
                                      Text(AppLocalizations.of(context)!.play),
                                  icon: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                    child: isLoading
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
                                          "id": widget.items[index].id!,
                                        }).toString());
                                  },
                                  child: Text(
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
              dotsCount: widget.items.length,
              position: _currentPage,
              decorator: DotsDecorator(
                activeColor: Theme.of(context).buttonTheme.colorScheme!.primary,
                activeShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0)),
                activeSize: const Size(40.0, 10.0),
                size: const Size(20, 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0)),
              ),
              onTap: (position) {
                _controller.animateToPage(position,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeIn);
              },
            ),
          ),
        ],
      ),
    );
  }
}
