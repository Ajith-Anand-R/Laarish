/// Laarish FX — the AAA motion/graphics toolkit.
///
/// One import gives a screen the whole vocabulary: particles, bursts, camera
/// shake, 3D tilt & depth, magnetic presses, glows, animated gradients,
/// parallax, motion blur, depth transitions and chain reactions.
///
///     import '../../core/fx/fx.dart';
///
/// Design rules for everything in here:
///   • composite-only where possible (Transform/Opacity/CustomPaint), so a
///     visual never triggers layout on the subtree it decorates;
///   • one shared clock per effect, wrapped in a [RepaintBoundary];
///   • slow ambient drift runs on ThrottledTicker (30fps), interactive
///     feedback runs at full display rate — visuals are never downgraded to
///     save frames (DESIGN_SYSTEM.md §5).
library;

export 'fx_glow.dart';
export 'fx_parallax.dart';
export 'fx_particles.dart';
export 'fx_press.dart';
export 'fx_shake.dart';
export 'fx_tilt.dart';
export 'fx_transitions.dart';
