import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jellyflix/components/item_carousel.dart';
import 'package:jellyflix/models/poster_type.dart';
import 'package:jellyflix/models/skeleton_item.dart';
import 'package:openapi/openapi.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FutureItemCarousel extends StatelessWidget {
  final String? title;
  final Function titleMapping;
  final Function imageMapping;
  final Function? subtitleMapping;
  final Function blurHashMapping;
  final Function? overlay;
  final PosterType posterType;
  final Function(int, String)? onTap;
  final Future future;

  const FutureItemCarousel({
    super.key,
    this.title,
    required this.titleMapping,
    required this.imageMapping,
    required this.blurHashMapping,
    this.subtitleMapping,
    this.overlay,
    this.posterType = PosterType.vertical,
    this.onTap,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          List<BaseItemDto> data =
              List.filled(Random().nextInt(4) + 3, SkeletonItem.baseItemDto);
          if (snapshot.hasData) {
            data = snapshot.data!;
            if (data.isEmpty) {
              return const SizedBox.shrink();
            }
          }
          return Skeletonizer(
            effect: const ShimmerEffect(),
            enabled: !snapshot.hasData,
            child: ItemCarousel(
                imageList: data.map((e) {
                  return imageMapping(e);
                }).toList(),
                titleList: data.map((e) {
                  return titleMapping(e);
                }).toList(),
                blurHashList: data.map((e) {
                  return blurHashMapping(e);
                }).toList(),
                subtitleList: subtitleMapping != null
                    ? data.map((e) {
                        return subtitleMapping!(e);
                      }).toList()
                    : null,
                posterType: posterType,
                onTap: (index) {
                  onTap!(index, data[index].id!);
                },
                overlay: overlay != null
                    ? data.map(((e) {
                        final index = data.indexOf(e);
                        final element = e;
                        return overlay!(index, element) as Widget;
                      })).toList()
                    : null,
                title: title),
          );
        });
  }
}
