import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/app/app.dart';
import 'package:laarish/app/providers.dart';
import 'package:laarish/app/router.dart';

/// End-to-end of the level gate: watch video → checkpoint (photo → verify →
/// quiz) → reward → next level. The camera is stubbed via [photoPickerProvider]
/// so the flow runs headless.
void main() {
  testWidgets('finish level: photo + correct quiz unlocks the next level', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoPickerProvider.overrideWithValue(() async => '/fake/plant.jpg'),
        ],
        child: const LaarishApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 500));

    // Into tommy level 1. Video can't init in the test host, so the level
    // shows its "coming soon" card whose button drives the same path.
    router.go('/level/tommy/1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Mark as watched'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // checkpoint enter

    // Photo step → capture (stubbed) → review → verify.
    await tester.tap(find.text('Take photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Verify & continue'));
    await tester.pump();

    // Quiz: level 1's correct answer is "Seeds and soil".
    await tester.tap(find.text('Seeds and soil'));
    await tester.pump(); // _finish mutate
    await tester.pump(const Duration(milliseconds: 500)); // reward overlay enter
    await tester.pump(const Duration(milliseconds: 900)); // reward rows chain in

    await tester.tap(find.text('Collect'));
    await tester.pump(); // pop overlay + go next level
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(seconds: 1)); // level-2 video init fails → card

    expect(tester.takeException(), isNull);
    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/level/tommy/2');
    expect(find.textContaining('LEVEL 2'), findsOneWidget);
  });
}
