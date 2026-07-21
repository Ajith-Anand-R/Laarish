import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cap the display to a ~60Hz mode. Deliberately NOT chasing 120Hz: the rich
  // parallax/shader/3D-reveal visuals are far easier to land jank-free with a
  // full 16ms frame budget than an 8ms one. On a 120Hz panel we pick the
  // highest-resolution ≤60Hz mode; if none exists we leave the default.
  // Fail-softs on desktop/web/iOS. See DESIGN_SYSTEM.md §5 perf convention.
  try {
    final modes = await FlutterDisplayMode.supported;
    final sixty = modes.where((m) => m.refreshRate >= 55 && m.refreshRate <= 61).toList()
      ..sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
    if (sixty.isNotEmpty) {
      await FlutterDisplayMode.setPreferredMode(sixty.first);
    }
  } catch (_) {/* no controllable display modes; keep the device default */}

  // No firebase_options.dart yet — run `flutterfire configure` (needs your
  // own Firebase account login in a browser; AGENT.md §2/§3). Until then the
  // app runs fully offline on StubAuthRepository so it stays playable.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  runApp(
    ProviderScope(
      overrides: [firebaseReadyProvider.overrideWithValue(firebaseReady)],
      child: const LaarishApp(),
    ),
  );
}
