import 'package:flutter/material.dart';
import '../theme/laarish_colors.dart';
import '../theme/laarish_spacing.dart';
import '../theme/laarish_text.dart';

/// Speech bubble with tail — always paired to a character. Used for canon
/// dialogue lines (CANON.md §2), never floating text.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text, this.tailAlignLeft = true});

  final String text;
  final bool tailAlignLeft;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TailPainter(left: tailAlignLeft),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: LaarishSpacing.md,
          vertical: LaarishSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: LaarishColors.bubble,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LaarishColors.ink, width: 2),
        ),
        child: Text(text, style: LaarishText.body16, textAlign: TextAlign.center),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter({required this.left});
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = LaarishColors.ink;
    final x = left ? size.width * 0.2 : size.width * 0.8;
    final path = Path()
      ..moveTo(x - 8, size.height - 2)
      ..lineTo(x + 8, size.height - 2)
      ..lineTo(x, size.height + 10)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
