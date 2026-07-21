import 'package:flutter/material.dart';
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
    );
  }
}
