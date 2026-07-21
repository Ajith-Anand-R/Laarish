import 'package:flutter/material.dart';
import '../theme/laarish_colors.dart';
import '../theme/laarish_spacing.dart';
import '../theme/laarish_text.dart';

/// Pill-shaped colored ribbon header — guidebook "PHASE 1 - NURSERY" style.
/// DESIGN_SYSTEM.md §3.
class RibbonBanner extends StatelessWidget {
  const RibbonBanner({super.key, required this.text, this.color = LaarishColors.leafDeep});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LaarishSpacing.lg, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text.toUpperCase(),
        style: LaarishText.display22.copyWith(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
