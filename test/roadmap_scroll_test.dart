import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/core/fx/fx.dart';

/// Regression guard for "ScrollController attached to multiple scroll views",
/// which crashed the roadmap mid-fling.
///
/// The map's camera FX read the same ScrollController the map scrolls with.
/// If a wrapper changes the widget *structure* as velocity crosses a threshold
/// (e.g. adding/removing an `ImageFiltered`), Flutter re-inflates the scroll
/// view below it — and the new Scrollable attaches the controller before the
/// old one detaches, blowing the `_positions.length == 1` assertion.
///
/// [ScrollCamera] is the wrapper that is allowed to sit above a scroll view,
/// so it must emit a constant structure (identity Transform at rest).
/// [VelocityBlur] deliberately does not, and is documented as
/// decorative-layers-only.
void main() {
  testWidgets('ScrollCamera keeps exactly one attached scroll position',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScrollCamera(
            controller: controller,
            child: ListView.builder(
              controller: controller,
              itemCount: 60,
              itemBuilder: (_, i) => SizedBox(height: 80, child: Text('row $i')),
            ),
          ),
        ),
      ),
    );

    expect(controller.positions.length, 1);

    // A hard fling drives the camera from rest, through saturation, and back —
    // exactly the transitions that used to re-inflate the scroll view.
    await tester.fling(find.byType(ListView), const Offset(0, -500), 5000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
    expect(controller.positions.length, 1, reason: 'scroll view was re-inflated');

    await tester.pumpAndSettle();
    expect(controller.positions.length, 1);
  });

  testWidgets('ScrollCamera settles back to rest and stops ticking',
      (tester) async {
    // The velocity sampler must sleep when the view is still — otherwise it
    // keeps a frame scheduled forever (battery on device, hung pumpAndSettle
    // in tests). pumpAndSettle completing at all is the assertion here.
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScrollCamera(
            controller: controller,
            child: ListView.builder(
              controller: controller,
              itemCount: 30,
              itemBuilder: (_, i) => SizedBox(height: 80, child: Text('r$i')),
            ),
          ),
        ),
      ),
    );

    await tester.fling(find.byType(ListView), const Offset(0, -300), 3000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
