import 'package:flutter/material.dart';
import '../motion/laarish_motion.dart';
import '../theme/laarish_colors.dart';
import '../theme/laarish_spacing.dart';
import '../theme/laarish_text.dart';

/// "Gummy" 3D button — DESIGN_SYSTEM.md §3: top-light gradient, darker rim,
/// presses down with squash. This is the ONLY button widget in the app —
/// no raw ElevatedButton/TextButton on child-facing screens.
class LaarishButton extends StatefulWidget {
  const LaarishButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = LaarishColors.sunflower,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;

  @override
  State<LaarishButton> createState() => _LaarishButtonState();
}

class _LaarishButtonState extends State<LaarishButton> {
  bool _pressed = false;

  Color get _deep => Color.alphaBlend(Colors.black.withValues(alpha: 0.18), widget.color);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? LaarishMotion.tapSquash : 1.0,
        duration: LaarishMotion.tapDown,
        curve: Curves.easeOut,
        child: Container(
          constraints: const BoxConstraints(minHeight: LaarishSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: LaarishSpacing.xl,
            vertical: LaarishSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [widget.color, _deep],
            ),
            boxShadow: [
              BoxShadow(
                color: _deep.withValues(alpha: 0.5),
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white),
                const SizedBox(width: LaarishSpacing.sm),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: LaarishText.button,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
