import 'package:flutter/material.dart';

class JfxTextTheme {
  static TextTheme scalingTheme(BuildContext context) {
    final TextTheme baseTextTheme =
        Theme.of(context).textTheme; // Get base text theme

    // Calculate font sizes based on wider dimension of viewport
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double sizeBaseline =
        screenWidth > screenHeight ? screenWidth : screenHeight;

    double headlineSmallSize = sizeBaseline * 0.018;
    if (headlineSmallSize < 24) {
      headlineSmallSize = 24;
    }
    double titleMediumSize = headlineSmallSize * 2 / 3;
    double bodyLargeSize = titleMediumSize * .875;
    double bodyMediumSize = bodyLargeSize * .875;
    double bodySmallSize = bodyMediumSize * .875;

    double headlineMediumSize = headlineSmallSize / .75;

    // Override the base text theme with custom font sizes
    return baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium!
            .copyWith(fontSize: headlineMediumSize),
        headlineSmall:
            baseTextTheme.headlineSmall!.copyWith(fontSize: headlineSmallSize),
        titleMedium:
            baseTextTheme.titleMedium!.copyWith(fontSize: titleMediumSize),
        bodyLarge: baseTextTheme.bodyLarge!.copyWith(fontSize: bodyLargeSize),
        bodyMedium:
            baseTextTheme.bodyMedium!.copyWith(fontSize: bodyMediumSize),
        bodySmall: baseTextTheme.bodySmall!.copyWith(fontSize: bodySmallSize));
  }
}
