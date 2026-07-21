import 'package:flutter/animation.dart';

/// Motion vocabulary — DESIGN_SYSTEM.md §4. Every UI entrance/exit/press
/// goes through these so the whole app feels like one physical world.
class LaarishMotion {
  LaarishMotion._();

  /// Spring pop: UI enters by scale 0 -> 1.05 -> 1.
  static const SpringDescription pop = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 20,
  );

  static const Duration tapDown = Duration(milliseconds: 60);
  static const Duration tapUp = Duration(milliseconds: 120);
  static const double tapSquash = 0.94;
  static const double tapOvershoot = 1.06;

  static const Curve enter = Curves.easeOutBack;
  static const Curve exit = Curves.easeInCubic;
  static const Curve camera = Curves.easeInOutCubic;

  static const Duration transition = Duration(milliseconds: 500);

  /// Stagger gap between cascading list/node entrances.
  static const Duration staggerStep = Duration(milliseconds: 55);
}
