import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/desktop_image_banner.dart';
import 'package:jellyflix/components/mobile_image_banner.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'dart:io';

import 'package:openapi/openapi.dart';

class ImageBanner extends HookConsumerWidget {
  final List<BaseItemDto> items;
  final Duration scrollDuration;
  final double? height;

  const ImageBanner(
      {super.key,
      required this.items,
      this.height = 500,
      this.scrollDuration = const Duration(seconds: 5)});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      if (Platform.isAndroid || Platform.isIOS) {
        return MobileImageBanner(
          items: items,
          height: height,
          scrollDuration: scrollDuration,
          onPressedPlay: onPressedPlay(ref, context),
        );
      } else {
        return DesktopImageBanner(
          items: items,
          height: 400,
          scrollDuration: scrollDuration,
          onPressedPlay: onPressedPlay(ref, context),
        );
      }
    });
  }

  onPressedPlay(WidgetRef ref, BuildContext context) {
    return (item) async {
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
      var playbackInfo = await ref
          .read(apiProvider)
          .getStreamUrlAndPlaybackInfo(itemId: itemId);
      if (context.mounted) {
        context.push(
            Uri(path: ScreenPaths.player, queryParameters: {
              "startTimeTicks": playbackStartTicks.toString()
            }).toString(),
            extra: playbackInfo);
      }
    };
  }
}
