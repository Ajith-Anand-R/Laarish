import 'dart:math' as math;
import 'dart:ui';

/// Pure geometry for the winding garden path — DESIGN_SYSTEM.md §6.
/// Shared by [GardenPathPainter] and the node-placement code in
/// [RoadmapScreen] so the path drawn and the nodes sitting on it always
/// agree, with zero duplicated math.
class PathGeometry {
  PathGeometry._();

  static const nodeCount = 20; // 4 plants x 5 levels, CANON.md journey order
  static const topPadding = 170.0;
  static const nodeSpacing = 170.0;
  static const bottomPadding = 240.0;

  static double totalHeight() =>
      topPadding + (nodeCount - 1) * nodeSpacing + bottomPadding;

  /// Center point of node [index] (0-based) for a path of the given [width].
  static Offset nodeOffset(int index, double width) {
    final amplitude = math.min(width * 0.30, width / 2 - 48);
    final x = width / 2 + math.sin((index + 0.5) * 1.1) * amplitude;
    final y = topPadding + index * nodeSpacing;
    return Offset(x, y);
  }

  static List<Offset> allNodeOffsets(double width) =>
      [for (var i = 0; i < nodeCount; i++) nodeOffset(i, width)];

  /// Smooth vertical S-curve through [points] — a Catmull-Rom spline converted
  /// to cubic Beziers. Interpolates every node exactly (the path lands on each
  /// bud) while staying C1-continuous, so the vine flows through the turns with
  /// no kinks at the joints. Endpoints duplicate the first/last node so the
  /// spline has tangents to work with there.
  static Path smoothPathThrough(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    if (points.length == 1) {
      path.moveTo(points.first.dx, points.first.dy);
      return path;
    }
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i == 0 ? 0 : i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[i + 2 < points.length ? i + 2 : points.length - 1];
      // Catmull-Rom -> Bezier control points (tension 0.5, the standard 1/6).
      final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }
}
