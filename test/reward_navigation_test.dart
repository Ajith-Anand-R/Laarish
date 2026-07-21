import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/app/app.dart';
import 'package:laarish/app/router.dart';

/// Guards the "collect reward → next level" flow. Completing a level credits
/// the reward, then the game should open the NEXT level (not the map). Also a
/// smoke guard for the roadmap crash: entering /map on a fresh mount used to
/// throw in `_RevealNode` (reading `viewportDimension` before layout) and
/// cascade into red-screen element-tree asserts.
void main() {
  testWidgets('collect reward opens the next level', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LaarishApp()));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 500));

    // Build the map shell first, matching the real journey.
    router.go('/map');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Into tommy level 1. The placeholder video can't init in the test host,
    // so LevelScreen falls back to the "coming soon" card whose
    // "Mark as watched" button drives the same completion path.
    router.go('/level/tommy/1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final markWatched = find.text('Mark as watched');
    expect(markWatched, findsOneWidget, reason: 'level did not fall back to coming-soon card');
    await tester.tap(markWatched);
    await tester.pump(); // run _complete up to the overlay
    await tester.pump(const Duration(milliseconds: 500)); // overlay enter

    await tester.tap(find.text('Tap to collect'));
    await tester.pump(); // pop overlay + go to the next level
    await tester.pump(const Duration(milliseconds: 700)); // next level enter
    // Let the level-2 screen's video init fail so it shows its coming-soon card.
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    // Landed on tommy level 2 (RibbonBanner reads "TOMMY · LEVEL 2").
    expect(find.textContaining('LEVEL 2'), findsOneWidget);
  });
}
