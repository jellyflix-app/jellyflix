import 'package:flutter/material.dart';
import 'package:jellyflix/components/jfx_text_theme.dart';

class JfxLayout {
  final double buttonHeight;
  final double tileWidth;
  final double tileHeight;
  final TextTheme text;
  final ColorScheme color;
  final double tilePadding;

  JfxLayout._(this.buttonHeight, this.tileWidth, this.tileHeight, this.text,
      this.color, this.tilePadding);

  static JfxLayout scalingLayout(BuildContext context) {
    double viewportWidth = MediaQuery.of(context).size.width;
    double viewportHeight = MediaQuery.of(context).size.height;
    double scaleBaseline =
        viewportWidth > viewportHeight ? viewportWidth : viewportHeight;

    double buttonHeight = (scaleBaseline * 0.05).roundToDouble();
    double tileWidth = (scaleBaseline * 0.11).roundToDouble();
    if (tileWidth < 100) {
      tileWidth = 100;
    }
    double tileHeight = (tileWidth * 3 / 2).roundToDouble();
    double tilePadding = (scaleBaseline * 0.012).roundToDouble();
    TextTheme text = JfxTextTheme.scalingTheme(context);
    ColorScheme color = Theme.of(context).colorScheme;

    // Remove context from the constructor call
    return JfxLayout._(
        buttonHeight, tileWidth, tileHeight, text, color, tilePadding);
  }
}
