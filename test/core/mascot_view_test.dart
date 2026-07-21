import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/core/widgets/mascot_view.dart';

/// Locks the visual-pass wiring: MascotView renders for a shipped mascot and
/// fails soft (no throw) for one whose art hasn't shipped (Okki). Energy map
/// stays canon-ordered (Okki hottest, Chilly coolest).
void main() {
  testWidgets('renders a shipped mascot and fails soft for a missing one', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              MascotView(asset: 'assets/images/tommy_mascot.png', size: 80),
              MascotView(asset: 'assets/images/okki_mascot.png', size: 80), // no art -> fallback
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600)); // entrance settles
    expect(tester.takeException(), isNull);
    expect(find.byType(MascotView), findsNWidgets(2));
  });

  test('idle energy follows canon personalities', () {
    expect(mascotEnergy('okki'), greaterThan(mascotEnergy('tommy')));
    expect(mascotEnergy('chilly'), lessThan(mascotEnergy('tommy')));
    expect(mascotEnergy('unknown'), 1.0);
  });
}
