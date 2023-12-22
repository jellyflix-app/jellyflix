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
  final Function subtitleMapping;
  final PosterType posterType;
  final Function(int, String)? onTap;
  final Future future;

  const FutureItemCarousel({
    super.key,
    this.title,
    required this.titleMapping,
    required this.imageMapping,
    required this.subtitleMapping,
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
                subtitleList: data.map((e) {
                  return subtitleMapping(e);
                }).toList(),
                posterType: posterType,
                onTap: (index) {
                  onTap!(index, data[index].id!);
                },
                title: title),
          );
        });
  }
}
