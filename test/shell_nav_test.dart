import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/app/app.dart';
import 'package:laarish/app/router.dart';

void main() {
  // Guards the ShellRoute wiring: entering the vine-dock shell from an outside
  // route and switching hub tabs must not corrupt the element tree.
  testWidgets('shell nav: enter and switch hub tabs without crashing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LaarishApp()));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 500));

    Future<void> visit(String loc) async {
      router.go(loc);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull, reason: 'crashed navigating to $loc');
    }

    // /certificate is outside the shell; going from it into /map exercises the
    // "enter shell from outside" path that reward → /map takes.
    await visit('/certificate');
    await visit('/map');
    await visit('/garden');
    await visit('/mentor');
    await visit('/badges');
    await visit('/settings');
    await visit('/map');
  });
}
