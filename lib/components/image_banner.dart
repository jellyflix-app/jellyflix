import 'package:flutter/material.dart';
import 'package:jellyflix/components/desktop_image_banner.dart';
import 'package:jellyflix/components/mobile_image_banner.dart';

import 'package:openapi/openapi.dart';

class ImageBanner extends StatelessWidget {
  final List<BaseItemDto> items;
  final Duration scrollDuration;
  final double? height;

  const ImageBanner(
      {super.key,
      required this.items,
      this.height = 600,
      this.scrollDuration = const Duration(seconds: 5)});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 600) {
        return DesktopImageBanner(
          items: items,
          height: 400,
          scrollDuration: scrollDuration,
        );
      } else {
        return MobileImageBanner(
          items: items,
          height: height,
          scrollDuration: scrollDuration,
        );
      }
    });
  }
}
