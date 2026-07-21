import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Motion vocabulary — DESIGN_SYSTEM.md §4. Every UI entrance/exit/press
/// goes through these so the whole app feels like one physical world.
///
/// The springs below are the app's "physics constants": nothing should invent
/// its own stiffness/damping numbers inline. Pick the spring whose *feel*
/// matches the gesture (pop for taps, snappy for swaps, heavy for big cards,
/// elastic for celebration) and let the simulation do the easing.
class LaarishMotion {
  LaarishMotion._();

  /// Spring pop: UI enters by scale 0 -> 1.05 -> 1.
  static const SpringDescription pop = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 20,
  );

  /// Fast, tight settle for element swaps and step transitions — barely
  /// overshoots, so rapid repeats never look sloppy.
  static const SpringDescription snappy = SpringDescription(
    mass: 0.8,
    stiffness: 700,
    damping: 28,
  );

  /// Weighty settle for large surfaces (sheets, hero cards) — reads as mass.
  static const SpringDescription heavy = SpringDescription(
    mass: 1.6,
    stiffness: 320,
    damping: 26,
  );

  /// Loose, bouncy celebration spring — several visible oscillations.
  static const SpringDescription elastic = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 11,
  );

  /// Magnetic return: how a pressed/dragged control snaps back to rest.
  static const SpringDescription magnet = SpringDescription(
    mass: 0.6,
    stiffness: 380,
    damping: 18,
  );

  static const Duration tapDown = Duration(milliseconds: 60);
  static const Duration tapUp = Duration(milliseconds: 120);
  static const double tapSquash = 0.94;
  static const double tapOvershoot = 1.06;

  static const Curve enter = Curves.easeOutBack;
  static const Curve exit = Curves.easeInCubic;
  static const Curve camera = Curves.easeInOutCubic;

  /// Anticipation — pulls *back* before it goes (classic 12-principles wind-up).
  static const Curve anticipate = Cubic(0.68, -0.55, 0.27, 1.55);

  /// Follow-through — arrives fast, drifts the last few pixels home.
  static const Curve followThrough = Cubic(0.12, 0.9, 0.2, 1.0);

  /// Big juicy overshoot for reward/star pops.
  static const Curve overshoot = Cubic(0.34, 1.9, 0.44, 1.0);

  static const Duration transition = Duration(milliseconds: 500);

  /// Stagger gap between cascading list/node entrances.
  static const Duration staggerStep = Duration(milliseconds: 55);

  /// Chain-reaction gap — used when N things must pop one after another
  /// (star row, reward counters, matched tiles).
  static const Duration chainStep = Duration(milliseconds: 90);

  /// Build a settle-to-[target] simulation from an unbounded controller's
  /// current [from]/[velocity]. Every spring release in the app routes here so
  /// press-release physics stay identical across buttons, nodes and cards.
  static SpringSimulation settle(
    double from,
    double target, {
    double velocity = 0,
    SpringDescription spring = pop,
  }) =>
      SpringSimulation(spring, from, target, velocity);
}
