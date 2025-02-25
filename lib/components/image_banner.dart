import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/image_banner_inner_landscape.dart';
import 'package:jellyflix/components/image_banner_inner_portrait.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:async/async.dart';
import 'package:jellyflix/providers/player_helper_provider.dart';

import 'package:tentacle/tentacle.dart';

class InteractionArea extends StatelessWidget {
  final void Function()? timerResetCallback;
  final Function(bool)? setHoveredCallback;
  final Widget child;

  const InteractionArea({
    super.key,
    required this.timerResetCallback,
    required this.child,
    this.setHoveredCallback,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        hitTestBehavior: HitTestBehavior.translucent,
        onEnter: (_) {
          timerResetCallback!();
          setHoveredCallback!(true);
        },
        onHover: (value) {
          // We intentionally don't set hovered here
          // Otherwise hovering the region with a touchscreen
          // would break scrolling until rebuild (no exit event)
          timerResetCallback!();
        },
        onExit: (_) {
          timerResetCallback!();
          setHoveredCallback!(false);
        },
        child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerMove: (event) {
              timerResetCallback!();
            },
            child: child));
  }
}

class ImageBanner extends StatefulHookConsumerWidget {
  final List<BaseItemDto> items;
  final Duration scrollInterval;
  final double? height;

  const ImageBanner(
      {super.key,
      required this.items,
      this.height = 500,
      this.scrollInterval = const Duration(seconds: 5)});
  @override
  ImageBannerState createState() => ImageBannerState();
}

class ImageBannerState extends ConsumerState<ImageBanner> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  RestartableTimer? _timer;
  bool hovered = false;
  bool playButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _timer = RestartableTimer(widget.scrollInterval, () {
      if (!playButtonPressed && !hovered) {
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
    return LayoutBuilder(builder: (context, constraints) {
      return InteractionArea(
          timerResetCallback: _timer?.reset,
          setHoveredCallback: (bool value) {
            setState(() {
              hovered = value;
            });
          },
          child: MediaQuery.of(context).orientation == Orientation.portrait
              ? ImageBannerInnerPortrait(
                  items: widget.items,
                  height: widget.height,
                  playButtonPressed: playButtonPressed,
                  onPressedPlay: onPressedPlay(ref, context),
                  controller: _controller,
                  currentPage: _currentPage,
                  setCurrentPageCallback: (int currentPage) =>
                      {setState(() => _currentPage = currentPage)})
              : ImageBannerInnerLandscape(
                  items: widget.items,
                  playButtonPressed: playButtonPressed,
                  onPressedPlay: onPressedPlay(ref, context),
                  controller: _controller,
                  currentPage: _currentPage,
                  setCurrentPageCallback: (int currentPage) =>
                      {setState(() => _currentPage = currentPage)}));
    });
  }

  onPressedPlay(WidgetRef ref, BuildContext context) {
    return (item) async {
      setState(() {
        playButtonPressed = true;
      });
      var itemId = item.id;
      var playbackStartTicks = item.userData?.playbackPositionTicks ?? 0;
      if (item.type == BaseItemKind.series) {
        List<BaseItemDto> continueWatching =
            await ref.read(apiProvider).getContinueWatching(parentId: item.id!);
        if (continueWatching.isNotEmpty) {
          itemId = continueWatching.first.id!;
          playbackStartTicks =
              continueWatching.first.userData!.playbackPositionTicks!;
        } else {
          List<BaseItemDto> result =
              await ref.read(apiProvider).getNextUpEpisode(seriesId: item.id!);
          if (result.isNotEmpty) {
            itemId = result.first.id!;
          } else {
            List<BaseItemDto> episodes =
                await ref.read(apiProvider).getEpisodes(item.id!);
            itemId = episodes.first.id!;
          }
        }
      }
      if (itemId == null) {
        return;
      }
      ref.read(streamPlayerHelperProvider(itemId).future).then((playerHelper) {
        if (context.mounted) {
          context.push(
            Uri(path: ScreenPaths.player, queryParameters: {
              "startTimeTicks": playbackStartTicks.toString()
            }).toString(),
            extra: playerHelper,
          );
          Future.delayed(const Duration(seconds: 1), () {
            setState(() {
              playButtonPressed = false;
            });
          });
        }
      });
    };
  }
}
