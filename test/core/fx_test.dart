import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/core/fx/fx.dart';

/// Guards the FX layer's contracts — the parts that would fail silently or
/// leak if they broke:
///   • [MagneticTap] still fires onTap (it replaced every GestureDetector in
///     the app, so a regression here makes the whole UI untappable);
///   • [FxBurst] inserts an overlay entry AND removes it when the animation
///     ends (a leak here piles up entries forever);
///   • [ShakeScope] survives a shake and settles back to identity;
///   • the ambient painters mount and dispose their tickers cleanly.
void main() {
  testWidgets('MagneticTap fires onTap and respects enabled:false', (tester) async {
    var taps = 0;
    var disabledTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MagneticTap(
                onTap: () => taps++,
                sfx: null,
                child: const SizedBox(width: 120, height: 60, child: Text('go')),
              ),
              MagneticTap(
                enabled: false,
                onTap: () => disabledTaps++,
                sfx: null,
                child: const SizedBox(width: 120, height: 60, child: Text('no')),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(taps, 1);

    await tester.tap(find.text('no'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(disabledTaps, 0, reason: 'disabled taps must not activate');
  });

  testWidgets('FxBurst adds an overlay entry and removes it when done',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    final before = tester.widgetList(find.byType(CustomPaint)).length;
    FxBurst.at(ctx, const Offset(100, 100), style: BurstStyle.celebrate);
    await tester.pump();
    expect(
      tester.widgetList(find.byType(CustomPaint)).length,
      greaterThan(before),
      reason: 'burst should have inserted a painting overlay',
    );

    // Longest burst is 1.4s; well past it the entry must have removed itself.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      tester.widgetList(find.byType(CustomPaint)).length,
      before,
      reason: 'burst overlay leaked — entry was never removed',
    );
  });

  testWidgets('ShakeScope shakes without throwing and settles', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ShakeScope(child: Scaffold(body: Center(child: Text('world')))),
      ),
    );

    final state = tester.state<ShakeScopeState>(find.byType(ShakeScope));
    state.shake(intensity: 12, haptic: HapticImpact.none);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(find.text('world'), findsOneWidget);
  });

  testWidgets('ambient FX mount and dispose cleanly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedMeshGradient(
                colors: [Colors.white, Colors.amber, Colors.green],
              ),
              ParticleField(count: 8),
              Center(
                child: PulseGlow(
                  color: Colors.amber,
                  child: ShimmerSweep(child: SizedBox(width: 50, height: 50)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);

    // Replacing the tree must dispose every ticker — a leaked one throws here.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ChainReveal eventually shows every child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ChainReveal(
              children: [Text('a'), Text('b'), Text('c')],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
  });
}
