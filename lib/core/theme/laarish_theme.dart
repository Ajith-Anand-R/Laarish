import 'package:flutter/material.dart';
import 'laarish_colors.dart';
import 'laarish_text.dart';

class LaarishTheme {
  LaarishTheme._();

  static ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: LaarishColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: LaarishColors.sunflower,
      brightness: Brightness.light,
      surface: LaarishColors.paper,
    ),
    textTheme: TextTheme(
      displayLarge: LaarishText.display34,
      displayMedium: LaarishText.display28,
      displaySmall: LaarishText.display22,
      bodyLarge: LaarishText.body18,
      bodyMedium: LaarishText.body16,
    ),
    // Every screen builds its own gamified chrome (DESIGN_SYSTEM.md) — no
    // default Material AppBar/Card look should ever be visible to a child.
  );
}
