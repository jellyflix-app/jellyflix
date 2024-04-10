import 'package:flutter/material.dart';
import 'package:jellyflix/components/jfx_text_theme.dart';

class JfxLayout {
  final double buttonHeight;
  final double tileWidth;
  final double tileHeight;
  final TextTheme text;
  final ColorScheme color;
  final double tileRightPadding;

  JfxLayout._(this.buttonHeight, this.tileWidth, this.tileHeight, this.text,
      this.color, this.tileRightPadding);

  static JfxLayout scalingLayout(BuildContext context) {
    double viewportWidth = MediaQuery.of(context).size.width;
    double viewportHeight = MediaQuery.of(context).size.height;
    double scaleBaseline =
        viewportWidth > viewportHeight ? viewportWidth : viewportHeight;

    double buttonHeight = scaleBaseline * 0.05;
    double tileWidth = scaleBaseline * 0.11;
    double tileHeight = tileWidth * 3 / 2;
    double tileRightPadding = scaleBaseline * 0.012;
    TextTheme text = JfxTextTheme.scalingTheme(context);
    ColorScheme color = Theme.of(context).colorScheme;

    // Remove context from the constructor call
    return JfxLayout._(
        buttonHeight, tileWidth, tileHeight, text, color, tileRightPadding);
  }
}
