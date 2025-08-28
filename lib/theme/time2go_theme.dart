import 'package:flutter/material.dart';

class Time2GoTheme extends ThemeExtension<Time2GoTheme> {
  final List<Color> blockColors;
  final Color gridColor;
  final Color backgroundColor;
  final Color foregroundColor;

  const Time2GoTheme({
    required this.blockColors,
    required this.gridColor,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  static Time2GoTheme of(BuildContext context) {
    final ext = Theme.of(context).extension<Time2GoTheme>();
    if (ext == null) {
      return const Time2GoTheme(
        blockColors: [
          Color(0xFF90CAF9),
          Color(0xFFA5D6A7),
          Color(0xFFFFF59D),
          Color(0xFFFFAB91),
          Color(0xFFCE93D8),
          Color(0xFFB0BEC5),
          Color(0xFFFFCC80),
          Color(0xFF80CBC4),
        ],
        gridColor: Color.fromARGB(80, 43, 43, 43),
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF000000),
      );
    }
    return ext;
  }

  @override
  Time2GoTheme copyWith({
    List<Color>? blockColors,
    Color? gridColor,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return Time2GoTheme(
      blockColors: blockColors ?? this.blockColors,
      gridColor: gridColor ?? this.gridColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
    );
  }

  @override
  Time2GoTheme lerp(ThemeExtension<Time2GoTheme>? other, double t) {
    if (other is! Time2GoTheme) return this;
    return Time2GoTheme(
      blockColors: List<Color>.generate(
        blockColors.length,
        (i) =>
            Color.lerp(blockColors[i], other.blockColors[i], t) ??
            blockColors[i],
      ),
      gridColor: Color.lerp(gridColor, other.gridColor, t) ?? gridColor,
      backgroundColor:
          Color.lerp(backgroundColor, other.backgroundColor, t) ??
          backgroundColor,
      foregroundColor:
          Color.lerp(foregroundColor, other.foregroundColor, t) ??
          foregroundColor,
    );
  }

  static const light = Time2GoTheme(
    blockColors: [
      Color(0xFF64B5F6),
      Color(0xFF81C784),
      Color(0xFFFFEE58),
      Color(0xFFFF8A65),
      Color(0xFFBA68C8),
      Color(0xFF90A4AE),
      Color(0xFFFFB74D),
      Color(0xFF4DB6AC),
    ],
    gridColor: Color.fromARGB(40, 0, 0, 0),
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: Color(0xFF000000),
  );

  static const dark = Time2GoTheme(
    blockColors: [
      Color(0xFF1976D2),
      Color(0xFF388E3C),
      Color(0xFFFBC02D),
      Color(0xFFD84315),
      Color(0xFF8E24AA),
      Color(0xFF455A64),
      Color(0xFFFB8C00),
      Color(0xFF00897B),
    ],
    gridColor: Color.fromARGB(40, 255, 255, 255),
    backgroundColor: Color(0xFF202020),
    foregroundColor: Color(0xFFFFFFFF),
  );
}
