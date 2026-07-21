import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/providers.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run the panel as fast as it will go — 120Hz where the device offers it.
  try {
    final modes = await FlutterDisplayMode.supported;
    if (modes.isNotEmpty) {
      final best = modes.toList()
        ..sort((a, b) {
          final byRate = b.refreshRate.compareTo(a.refreshRate);
          return byRate != 0
              ? byRate
              : (b.width * b.height).compareTo(a.width * a.height);
        });
      await FlutterDisplayMode.setPreferredMode(best.first);
    }
  } catch (_) {}

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase init error: $e');
    firebaseReady = false;
  }

  runApp(
    ProviderScope(
      overrides: [firebaseReadyProvider.overrideWithValue(firebaseReady)],
      child: const LaarishApp(),
    ),
  );
}
