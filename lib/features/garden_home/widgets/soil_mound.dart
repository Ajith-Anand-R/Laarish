import 'package:flutter/material.dart';
import '../../../core/theme/laarish_colors.dart';
import '../../../core/theme/laarish_text.dart';

/// GAMIFICATION.md §4 sprout countdown — "soil mound with animated '?' that
/// cracks a little each day". Pure CustomPaint, no image assets.
class SoilMound extends StatelessWidget {
  const SoilMound({super.key, required this.daysElapsed, required this.totalDays, required this.plantId});

  final int daysElapsed;
  final int totalDays;
  final String plantId;

  @override
  Widget build(BuildContext context) {
    final progress = totalDays <= 0 ? 1.0 : (daysElapsed / totalDays).clamp(0.0, 1.0);
    final biome = LaarishColors.biome[plantId] ?? LaarishColors.leafDeep;
    final daysLeft = (totalDays - daysElapsed).clamp(0, totalDays);

    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 72,
          child: CustomPaint(painter: _SoilMoundPainter(progress: progress, biome: biome)),
        ),
        const SizedBox(height: 4),
        Text(
          daysLeft <= 0 ? 'Any day now!' : 'Sprouts in ~$daysLeft day${daysLeft == 1 ? '' : 's'}',
          style: LaarishText.body16.copyWith(color: LaarishColors.soil),
        ),
      ],
    );
  }
}

class _SoilMoundPainter extends CustomPainter {
  _SoilMoundPainter({required this.progress, required this.biome});
  final double progress;
  final Color biome;

  @override
  void paint(Canvas canvas, Size size) {
    final moundRect = Rect.fromLTWH(0, size.height * 0.35, size.width, size.height * 0.65);
    final moundPath = Path()
      ..moveTo(moundRect.left, moundRect.bottom)
      ..quadraticBezierTo(moundRect.left, moundRect.top, moundRect.center.dx, moundRect.top)
      ..quadraticBezierTo(moundRect.right, moundRect.top, moundRect.right, moundRect.bottom)
      ..close();
    canvas.drawPath(moundPath, Paint()..color = LaarishColors.soil);

    // Cracks grow with progress — a little more each day.
    final crackPaint = Paint()
      ..color = LaarishColors.paper.withValues(alpha: 0.5 + 0.4 * progress)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final crackLen = size.width * 0.18 * progress;
    if (crackLen > 0) {
      final cx = moundRect.center.dx;
      final cy = moundRect.top + 4;
      canvas.drawLine(Offset(cx, cy), Offset(cx - crackLen, cy + crackLen * 0.6), crackPaint);
      canvas.drawLine(Offset(cx, cy), Offset(cx + crackLen * 0.8, cy + crackLen * 0.5), crackPaint);
    }

    // A sprout tip pokes through once progress is complete.
    if (progress >= 1.0) {
      final tipPaint = Paint()..color = biome;
      final cx = moundRect.center.dx;
      final tip = Path()
        ..moveTo(cx, moundRect.top)
        ..quadraticBezierTo(cx - 6, moundRect.top - 14, cx, moundRect.top - 22)
        ..quadraticBezierTo(cx + 6, moundRect.top - 14, cx, moundRect.top);
      canvas.drawPath(tip, tipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoilMoundPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.biome != biome;
}
