import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/item_carousel.dart';
import 'package:jellyflix/models/poster_type.dart';
import 'package:jellyflix/models/skeleton_item.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PaginatedItemCarousel extends StatefulHookConsumerWidget {
  final String? title;
  final Function titleMapping;
  final Function imageMapping;
  final Function? subtitleMapping;
  final Function blurHashMapping;
  final Function? overlay;
  final PosterType posterType;
  final Function(int, String)? onTap;
  final Future Function(int startIndex, int limit) future;

  final int pageSize;

  const PaginatedItemCarousel({
    super.key,
    this.title,
    required this.titleMapping,
    required this.imageMapping,
    required this.blurHashMapping,
    this.subtitleMapping,
    this.overlay,
    this.posterType = PosterType.vertical,
    this.onTap,
    this.pageSize = 10,
    required this.future,
  });

  @override
  ConsumerState<PaginatedItemCarousel> createState() =>
      _FutureItemCarouselState();
}

class _FutureItemCarouselState extends ConsumerState<PaginatedItemCarousel> {
  List data = [];

  int startIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);
    final isLastPage = useState(false);

    if (data.isEmpty && !isLastPage.value) {
      if (isLoading.hasListeners) {
        isLoading.value = true;
      }
      widget.future(startIndex, widget.pageSize).then((value) {
        data.addAll(value);
        startIndex += widget.pageSize;
        if (isLoading.hasListeners) {
          isLoading.value = false;
        }
        if (value.length < widget.pageSize && isLastPage.hasListeners) {
          isLastPage.value = true;
        }
      });
    }

    if (isLoading.value && !isLastPage.value && data.isEmpty) {
      var stubData =
          List.filled(Random().nextInt(7) + 3, SkeletonItem.baseItemDto);
      return Skeletonizer(
        effect: const ShimmerEffect(),
        enabled: true,
        child: ItemCarousel(
            imageList: stubData.map((e) {
              return widget.imageMapping(e);
            }).toList(),
            titleList: stubData.map((e) {
              return widget.titleMapping(e);
            }).toList(),
            blurHashList: stubData.map((e) {
              return widget.blurHashMapping(e);
            }).toList(),
            subtitleList: widget.subtitleMapping != null
                ? stubData.map((e) {
                    return widget.subtitleMapping!(e);
                  }).toList()
                : null,
            posterType: widget.posterType,
            title: widget.title),
      );
    }

    if (isLastPage.value && data.isEmpty) {
      return const SizedBox.shrink();
    }

    return ItemCarousel(
        onEnd: () {
          if (isLoading.value == false && !isLastPage.value) {
            isLoading.value = true;
            widget.future(startIndex + widget.pageSize, widget.pageSize).then(
              (value) {
                data.addAll(value);
                startIndex += widget.pageSize;
                // keep loading state if on last page
                if (value.length < widget.pageSize) {
                  isLastPage.value = true;
                }
                isLoading.value = false;
              },
            );
          }
        },
        imageList: data.map((e) {
          return widget.imageMapping(e);
        }).toList(),
        titleList: data.map((e) {
          return widget.titleMapping(e);
        }).toList(),
        blurHashList: data.map((e) {
          return widget.blurHashMapping(e);
        }).toList(),
        subtitleList: widget.subtitleMapping != null
            ? data.map((e) {
                return widget.subtitleMapping!(e);
              }).toList()
            : null,
        posterType: widget.posterType,
        onTap: (index) {
          widget.onTap!(index, data[index].id!);
        },
        overlay: widget.overlay != null
            ? data.map(((e) {
                final index = data.indexOf(e);
                final element = e;
                return widget.overlay!(index, element) as Widget;
              })).toList()
            : null,
        title: widget.title);
  }
}
