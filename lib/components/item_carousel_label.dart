import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:jellyflix/components/jfx_layout.dart';

class ItemCarouselLabel extends StatelessWidget {
  final String? title;
  final ScrollController scrollController;
  final double offsetWidth;

  const ItemCarouselLabel({
    super.key,
    this.title,
    required this.scrollController,
    required this.offsetWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        title == null
            ? const SizedBox()
            : Expanded(
                child: Text(
                  title!,
                  style: JfxTextTheme.scalingTheme(context).headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS)
          const Spacer(),
        if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS)
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            hoverColor:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
            onPressed: () {
              scrollController.animateTo(
                scrollController.offset - offsetWidth,
                curve: Curves.easeInOut,
                duration: const Duration(milliseconds: 400),
              );
            },
          ),
        if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS)
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            hoverColor:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
            onPressed: () {
              scrollController.animateTo(
                scrollController.offset + offsetWidth,
                curve: Curves.easeInOut,
                duration: const Duration(milliseconds: 400),
              );
            },
          ),
      ],
    );
  }
}
