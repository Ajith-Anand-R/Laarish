import 'package:flutter/material.dart';

/// Palette from CANON.md visual canon + DESIGN_SYSTEM.md §1 (guidebook cream/sunflower/leaf).
class LaarishColors {
  LaarishColors._();

  static const paper = Color(0xFFFDF6E7);
  static const paperDeep = Color(0xFFF5E9D0);

  static const skyTop = Color(0xFF87CEEB);
  static const skyBottom = Color(0xFFBFE3F5);

  static const sunflower = Color(0xFFFFC93C);
  static const sunflowerDeep = Color(0xFFF5A623);

  static const leaf = Color(0xFF58A83C);
  static const leafDeep = Color(0xFF2F6B2F);

  static const tomato = Color(0xFFD93025);

  static const chiliRed = Color(0xFFC62828);
  static const chiliFlame = Color(0xFFFF8F3C);

  static const soil = Color(0xFF7A5230);
  static const ink = Color(0xFF3A2E24);
  static const bubble = Color(0xFFFFFFFF);

  /// Per-plant biome tint, keyed by canon plantId (tommy/okki/chilly/methi).
  static const Map<String, Color> biome = {
    'tommy': tomato,
    'okki': leaf,
    'chilly': chiliRed,
    'methi': Color(0xFFA8D93C),
  };
}
