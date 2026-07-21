import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/motion/micro_animations.dart';
import '../../../core/theme/laarish_colors.dart';
import '../../../core/theme/laarish_text.dart';

/// Maps a badge id (badge_rules.dart) to its gold-seal artwork basename in
/// assets/images/. Camel-case ids -> snake-case files.
const Map<String, String> badgeAsset = {
  'tommy_firstSprout': 'badge_tommy_sprout',
  'tommy_firstHarvest': 'badge_tommy_harvest',
  'okki_firstSprout': 'badge_okki_sprout',
  'okki_firstHarvest': 'badge_okki_harvest',
  'chilly_firstSprout': 'badge_chilly_sprout',
  'chilly_firstHarvest': 'badge_chilly_harvest',
  'methi_round1Harvest': 'badge_methi_round1',
  'methi_round2Harvest': 'badge_methi_round2',
  'firstSeed': 'badge_first_seed',
  'thinningBrave': 'badge_thinning_brave',
  'graduationDay': 'badge_graduation_day',
  'bigMove': 'badge_big_move',
  'firstFlower': 'badge_first_flower',
  'fiveRulesKeeper': 'badge_five_rules',
  'patienceMaster': 'badge_patience_master',
  'photoReporter': 'badge_photo_reporter',
  'curiousMind': 'badge_curious_mind',
  'streak3': 'badge_streak_3',
  'streak7': 'badge_streak_7',
  'streak14': 'badge_streak_14',
  'streak30': 'badge_streak_30',
  'proudAgriculturist': 'badge_proud_agriculturist',
};

/// Gold-seal rosette badge — CANON.md §6. Shows the real seal artwork:
/// earned = full-colour, gently breathing; unearned = faded greyscale
/// silhouette (Badge Book empty-slot look, GAMIFICATION.md §2). Falls back to
/// the code-drawn rosette if the art is missing.
class BadgeRosette extends StatelessWidget {
  const BadgeRosette({
    super.key,
    required this.id,
    required this.title,
    required this.earned,
    this.size = 96,
  });

  final String id;
  final String title;
  final bool earned;
  final double size;

  // Luminance matrix — desaturates unearned badges to a silhouette.
  static const List<double> _grey = [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final asset = 'assets/images/${badgeAsset[id] ?? 'badge_first_seed'}.png';
    Widget art = Image.asset(
      asset,
      width: size,
      height: size * 1.2,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => CustomPaint(
        size: Size(size, size * 1.2),
        painter: _RosettePainter(earned: earned),
      ),
    );

    if (earned) {
      art = Breathing(amount: 0.02, child: art);
    } else {
      art = Opacity(
        opacity: 0.4,
        child: ColorFiltered(colorFilter: const ColorFilter.matrix(_grey), child: art),
      );
    }

    // Fit the medallion + title into whatever cell the grid gives us — the art
    // scales down inside the available space so tiles never overflow by a pixel.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(width: size, height: size * 1.2, child: art),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: LaarishText.body16.copyWith(
            fontSize: 11,
            height: 1.05,
            color: earned ? LaarishColors.ink : LaarishColors.soil.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _RosettePainter extends CustomPainter {
  _RosettePainter({required this.earned});
  final bool earned;

  @override
  void paint(Canvas canvas, Size size) {
    final gold = earned ? LaarishColors.sunflowerDeep : LaarishColors.paperDeep;
    final ribbon = earned ? LaarishColors.tomato : LaarishColors.soil.withValues(alpha: 0.15);
    final outline = earned
        ? LaarishColors.sunflowerDeep.withValues(alpha: 0.6)
        : LaarishColors.soil.withValues(alpha: 0.3);

    final circleRadius = size.width * 0.42;
    final center = Offset(size.width / 2, circleRadius + 4);

    // Ribbon tails first (behind the medallion).
    final ribbonPaint = Paint()..color = ribbon;
    final tailWidth = size.width * 0.16;
    final leftTail = Path()
      ..moveTo(center.dx - tailWidth, center.dy)
      ..lineTo(center.dx - tailWidth * 1.4, size.height)
      ..lineTo(center.dx - tailWidth * 0.3, size.height - tailWidth)
      ..lineTo(center.dx, center.dy)
      ..close();
    final rightTail = Path()
      ..moveTo(center.dx + tailWidth, center.dy)
      ..lineTo(center.dx + tailWidth * 1.4, size.height)
      ..lineTo(center.dx + tailWidth * 0.3, size.height - tailWidth)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(leftTail, ribbonPaint);
    canvas.drawPath(rightTail, ribbonPaint);

    // Scalloped rosette edge: ring of small circles under the medallion.
    final scallopPaint = Paint()..color = gold;
    const scallops = 14;
    for (var i = 0; i < scallops; i++) {
      final angle = (2 * math.pi / scallops) * i;
      final scallopCenter =
          center + Offset(circleRadius * 0.92 * math.cos(angle), circleRadius * 0.92 * math.sin(angle));
      canvas.drawCircle(scallopCenter, circleRadius * 0.16, scallopPaint);
    }

    // Medallion.
    canvas.drawCircle(center, circleRadius, scallopPaint);
    canvas.drawCircle(
      center,
      circleRadius,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      center,
      circleRadius * 0.65,
      Paint()..color = earned ? Colors.white.withValues(alpha: 0.85) : LaarishColors.paper,
    );

    // Star at center — stand-in "plant icon" (CANON.md badge art says a
    // plant icon; a star reads cleanly at small album-tile sizes without
    // needing a per-plant asset that doesn't exist yet).
    _drawStar(
      canvas,
      center,
      circleRadius * 0.4,
      earned ? LaarishColors.sunflowerDeep : LaarishColors.soil.withValues(alpha: 0.25),
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    const points = 5;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = (math.pi / points) * i - math.pi / 2;
      final p = center + Offset(r * math.cos(angle), r * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RosettePainter oldDelegate) => oldDelegate.earned != earned;
}
