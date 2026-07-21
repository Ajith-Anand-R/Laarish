import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/theme/laarish_colors.dart';
import 'path_geometry.dart';

/// Draws the winding garden path — DESIGN_SYSTEM.md §6:
/// - 4 biome bands cross-fading vertically (one LinearGradient does this for
///   free: Flutter interpolates linearly between adjacent color stops).
/// - dashed "footstep" texture along the S-curve.
/// - completed portion swept in green (vine look) up to [completedThrough].
///
/// Perf: this paints only when [shouldRepaint] says something meaningful
/// changed (size or completion count) — the caller wraps it in a
/// RepaintBoundary so the compositor caches the resulting layer exactly like
/// a pre-recorded Picture would, without hand-rolling a PictureRecorder.
class GardenPathPainter extends CustomPainter {
  GardenPathPainter({
    required this.points,
    required this.plantOrder,
    required this.completedThrough,
  });

  final List<Offset> points;
  final List<String> plantOrder;
  /// How many nodes (0..points.length) are "done" — the vine sweep fills up
  /// to this fraction of the path length.
  final int completedThrough;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBiomeBands(canvas, size);
    final path = PathGeometry.smoothPathThrough(points);
    _paintDashedFootsteps(canvas, path);
    _paintVine(canvas, path);
  }

  void _paintBiomeBands(Canvas canvas, Size size) {
    final perBiome = points.length / plantOrder.length;
    final colors = <Color>[];
    final stops = <double>[];
    for (var b = 0; b < plantOrder.length; b++) {
      final color = LaarishColors.biome[plantOrder[b]] ?? LaarishColors.leafDeep;
      final start = (b * perBiome) / points.length;
      final end = ((b + 1) * perBiome) / points.length;
      colors.add(color.withValues(alpha: 0.16));
      stops.add(start);
      colors.add(color.withValues(alpha: 0.16));
      stops.add(b == plantOrder.length - 1 ? 1.0 : end);
    }
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: stops,
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  void _paintDashedFootsteps(Canvas canvas, Path path) {
    final paint = Paint()
      ..color = LaarishColors.soil.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    for (final metric in path.computeMetrics()) {
      const step = 26.0;
      var distance = 0.0;
      var leftFoot = true;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          final perp = Offset(-tangent.vector.dy, tangent.vector.dx);
          final side = leftFoot ? 8.0 : -8.0;
          final center = tangent.position + perp * side;
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(tangent.angle);
          canvas.drawOval(const Rect.fromLTWH(-4, -6, 8, 12), paint);
          canvas.restore();
          leftFoot = !leftFoot;
        }
        distance += step;
      }
    }
  }

  /// The completed portion of the trail, drawn as a lush multi-layer vine:
  /// grounding shadow, soft outer glow, a gradient body, a glossy highlight
  /// ridge, and little leaves sprouting alternately along its length. All of
  /// this is static (only repaints when [completedThrough] changes) and the
  /// caller caches it in a RepaintBoundary, so the richness is effectively
  /// free during scrolling.
  void _paintVine(Canvas canvas, Path path) {
    if (completedThrough <= 0 || points.length < 2) return;
    final fraction = (completedThrough / (points.length - 1)).clamp(0.0, 1.0);

    for (final metric in path.computeMetrics()) {
      final sweptLen = metric.length * fraction;
      if (sweptLen <= 0) continue;
      final vine = metric.extractPath(0, sweptLen);
      final rect = vine.getBounds();

      // Grounding shadow (offset down + blurred) so the vine sits on the soil.
      canvas.save();
      canvas.translate(0, 4);
      canvas.drawPath(
        vine,
        Paint()
          ..color = LaarishColors.ink.withValues(alpha: 0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 13
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.restore();

      // Soft green aura.
      canvas.drawPath(
        vine,
        Paint()
          ..color = LaarishColors.leaf.withValues(alpha: 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );

      // Vine body — vertical gradient from deep to bright leaf.
      canvas.drawPath(
        vine,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [LaarishColors.leaf, LaarishColors.leafDeep],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Glossy highlight ridge along the top of the tube.
      canvas.save();
      canvas.translate(0, -2.2);
      canvas.drawPath(
        vine,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();

      _paintLeaves(canvas, metric, sweptLen);
    }
  }

  /// Small leaves sprouting alternately left/right along the swept vine.
  void _paintLeaves(Canvas canvas, PathMetric metric, double sweptLen) {
    const step = 46.0;
    final leafFill = LaarishColors.biome['methi'] ?? LaarishColors.leaf;
    var distance = 24.0;
    var left = true;
    while (distance < sweptLen - 6) {
      final t = metric.getTangentForOffset(distance);
      if (t != null) {
        final perp = Offset(-t.vector.dy, t.vector.dx);
        final side = left ? 1.0 : -1.0;
        final base = t.position + perp * (7.0 * side);
        canvas.save();
        canvas.translate(base.dx, base.dy);
        canvas.rotate(t.angle + (left ? 0.7 : -0.7));
        final leaf = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(5, -5, 3, -13)
          ..quadraticBezierTo(-1, -6, 0, 0)
          ..close();
        canvas.drawPath(
          leaf,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(leafFill, Colors.white, 0.35)!, leafFill],
            ).createShader(const Rect.fromLTWH(-4, -14, 10, 16)),
        );
        // Center vein.
        canvas.drawLine(
          Offset.zero,
          const Offset(2.2, -11),
          Paint()
            ..color = LaarishColors.leafDeep.withValues(alpha: 0.6)
            ..strokeWidth = 0.8,
        );
        canvas.restore();
        left = !left;
      }
      distance += step;
    }
  }

  @override
  bool shouldRepaint(covariant GardenPathPainter oldDelegate) {
    return oldDelegate.points.length != points.length ||
        oldDelegate.completedThrough != completedThrough ||
        !_offsetsEqual(oldDelegate.points, points);
  }

  bool _offsetsEqual(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
