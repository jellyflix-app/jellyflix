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

    double titleMediumSize = headlineSmallSize * 2 / 3;

    double bodyLargeSize = titleMediumSize * .875;

    // Override the base text theme with custom font sizes
    return baseTextTheme.copyWith(
      headlineSmall:
          baseTextTheme.headlineSmall!.copyWith(fontSize: headlineSmallSize),
      titleMedium:
          baseTextTheme.titleMedium!.copyWith(fontSize: titleMediumSize),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(fontSize: bodyLargeSize),
    );
  }
}

class JfxLayout {
  final double tileWidth;
  final double tileHeight;
  final TextTheme text;

  JfxLayout._(this.tileWidth, this.tileHeight, this.text);

  static JfxLayout scalingLayout(BuildContext context) {
    double viewportWidth = MediaQuery.of(context).size.width;
    double viewportHeight = MediaQuery.of(context).size.height;
    double scaleBaseline =
        viewportWidth > viewportHeight ? viewportWidth : viewportHeight;
    double tileWidth = scaleBaseline * 0.14;
    double tileHeight = tileWidth * 4 / 3;
    TextTheme text = JfxTextTheme.scalingTheme(context);

    // Remove context from the constructor call
    return JfxLayout._(tileWidth, tileHeight, text);
  }
}
