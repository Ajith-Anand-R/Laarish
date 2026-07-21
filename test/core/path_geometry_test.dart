import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/features/roadmap/path_geometry.dart';

void main() {
  group('PathGeometry.smoothPathThrough', () {
    test('interpolates every node (Catmull-Rom passes through control points)', () {
      final pts = PathGeometry.allNodeOffsets(390);
      final path = PathGeometry.smoothPathThrough(pts);
      final metrics = path.computeMetrics().toList();
      expect(metrics, isNotEmpty);

      final metric = metrics.first;
      // Start lands on the first node.
      final start = metric.getTangentForOffset(0)!.position;
      expect((start - pts.first).distance, lessThan(0.5));
      // End lands on the last node.
      final end = metric.getTangentForOffset(metric.length)!.position;
      expect((end - pts.last).distance, lessThan(0.5));
    });

    test('degenerate inputs do not throw', () {
      expect(PathGeometry.smoothPathThrough(const <Offset>[]).computeMetrics().isEmpty, isTrue);
      PathGeometry.smoothPathThrough(const [Offset(10, 10)]); // single point, no crash
    });
  });
}
