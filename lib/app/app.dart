import 'package:flutter/material.dart';
import '../core/fx/fx.dart';
import '../core/theme/laarish_theme.dart';
import 'router.dart';

class LaarishApp extends StatelessWidget {
  const LaarishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Laarish',
      debugShowCheckedModeBanner: false,
      theme: LaarishTheme.light,
      routerConfig: router,
      // One app-wide camera. Any screen can knock it with
      // `ShakeScope.go(context)` on an impact — level complete, correct
      // answer, node unlock — and the whole world (HUD, dialogs, particles)
      // shakes together, because they all live inside this one Transform.
      builder: (context, child) => ShakeScope(child: child ?? const SizedBox()),
    );
  }
}
