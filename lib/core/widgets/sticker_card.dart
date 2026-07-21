import 'package:flutter/material.dart';
import '../theme/laarish_colors.dart';
import '../theme/laarish_spacing.dart';

/// Guidebook sticker card: cream card, rounded-24, thin outline, soft shadow.
/// DESIGN_SYSTEM.md §3.
class StickerCard extends StatelessWidget {
  const StickerCard({super.key, required this.child, this.padding, this.color});

  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(LaarishSpacing.md),
      decoration: BoxDecoration(
        color: color ?? LaarishColors.bubble,
        borderRadius: BorderRadius.circular(LaarishSpacing.cardRadius),
        border: Border.all(color: LaarishColors.soil.withValues(alpha: 0.15), width: 2),
        boxShadow: [
          BoxShadow(
            color: LaarishColors.soil.withValues(alpha: 0.15),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}
