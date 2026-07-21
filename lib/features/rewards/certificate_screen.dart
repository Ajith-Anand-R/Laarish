import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../app/providers.dart';
import '../../core/fx/fx.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/sticker_card.dart';
import '../../data/local/entities.dart' as entities;
import '../../domain/reward_table.dart';
import 'reward_overlay.dart';

/// S12 — animated gold-seal certificate (PLAN.md flow: Profession Completed
/// -> Proud Agriculturist Badge -> Certificate). Reached from the roadmap
/// once `UnlockPolicy.professionComplete` is true (that entry point is
/// unchanged — see roadmap_screen.dart).
class CertificateScreen extends ConsumerStatefulWidget {
  const CertificateScreen({super.key});

  @override
  ConsumerState<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends ConsumerState<CertificateScreen> {
  final _captureKey = GlobalKey();
  bool _celebrated = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_celebrated) return;
    _celebrated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _awardAndCelebrate());
  }

  Future<void> _awardAndCelebrate() async {
    final save = ref.read(gameSaveProvider).value;
    if (save == null) return;
    final alreadyAwarded = save.badges.any((b) => b.id == 'proudAgriculturist');
    if (!alreadyAwarded) {
      await ref.read(gameSaveProvider.notifier).mutate((s) {
        s.badges.add(entities.Badge(id: 'proudAgriculturist', earnedAt: DateTime.now()));
        return s;
      });
    }
    if (!mounted) return;
    await showRewardOverlay(context, RewardTable.professionComplete, big: true);
  }

  Future<void> _saveAsImage() async {
    setState(() => _saving = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/laarish_certificate_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to ${file.path}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(gameSaveProvider);
    return Scaffold(
      backgroundColor: LaarishColors.paper,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ceremony lighting: a slow gold field with sparkles rising through
          // it. Deliberately OUTSIDE the RepaintBoundary that gets captured to
          // PNG, so the saved certificate stays a clean printable document.
          const RepaintBoundary(
            child: AnimatedMeshGradient(
              colors: [
                LaarishColors.paper,
                Color(0x44FFC93C),
                Color(0x2AF5A623),
                Color(0x1FD93025),
              ],
            ),
          ),
          const RepaintBoundary(
            child: ParticleField(
              color: LaarishColors.sunflower,
              style: ParticleStyle.sparkle,
              count: 26,
              speed: 1.0,
              opacity: 0.6,
            ),
          ),
          SafeArea(
        child: save.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (game) => Padding(
            padding: const EdgeInsets.all(LaarishSpacing.lg),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    // The certificate is a physical object you can tilt to
                    // catch the light — the foil-stamp feel.
                    child: Tilt3D(
                      maxTilt: 0.16,
                      deviceTiltAmount: 0.6,
                      child: RepaintBoundary(
                        key: _captureKey,
                        child: _Certificate(childName: game.profile.name),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: LaarishSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LaarishButton(
                      label: _saving ? 'Saving…' : 'Save as Image',
                      color: LaarishColors.leafDeep,
                      icon: Icons.download_rounded,
                      onTap: _saving ? () {} : _saveAsImage,
                    ),
                    const SizedBox(width: LaarishSpacing.md),
                    LaarishButton(
                      label: 'Back to Garden',
                      color: LaarishColors.sunflowerDeep,
                      hero: true,
                      icon: Icons.local_florist_rounded,
                      onTap: () => context.go('/garden'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}

class _Certificate extends StatefulWidget {
  const _Certificate({required this.childName});
  final String childName;

  @override
  State<_Certificate> createState() => _CertificateState();
}

class _CertificateState extends State<_Certificate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.childName.trim().isEmpty ? 'Future Agriculturist' : widget.childName;
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      child: StickerCard(
        color: LaarishColors.paper,
        padding: const EdgeInsets.all(LaarishSpacing.xl),
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: LaarishSpacing.md, vertical: 6),
                decoration: BoxDecoration(
                  color: LaarishColors.leafDeep,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'CERTIFICATE OF AGRICULTURE',
                  style: LaarishText.body16.copyWith(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(height: LaarishSpacing.lg),
              Text('I\'m An Agriculturist', style: LaarishText.display28, textAlign: TextAlign.center),
              const SizedBox(height: LaarishSpacing.sm),
              Text('This certifies that', style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
              const SizedBox(height: 4),
              Text(name, style: LaarishText.display34.copyWith(color: LaarishColors.tomato)),
              const SizedBox(height: 4),
              Text(
                'grew all four Laarish plants — Tommy, Okki, Chilly & Methi.',
                textAlign: TextAlign.center,
                style: LaarishText.body16.copyWith(color: LaarishColors.soil),
              ),
              const SizedBox(height: LaarishSpacing.lg),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Transform.rotate(
                  angle: (1 - _controller.value) * -0.6,
                  child: Image.asset(
                    'assets/images/cert_seal.png',
                    width: 130,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => CustomPaint(
                      size: const Size(120, 140),
                      painter: _GoldSealPainter(shine: _controller.value),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated gold seal — CustomPaint, no image asset. Rosette medallion +
/// ribbon tails, same gold-seal language as CANON.md §6 badge art, with a
/// star burst behind it for the "Proud Agriculturist" grand moment.
class _GoldSealPainter extends CustomPainter {
  _GoldSealPainter({required this.shine});
  final double shine;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.36);
    final radius = size.width * 0.36;

    // Sunburst rays behind the seal.
    final rayPaint = Paint()..color = LaarishColors.sunflower.withValues(alpha: 0.5 * shine);
    const rays = 16;
    for (var i = 0; i < rays; i++) {
      final angle = (2 * math.pi / rays) * i;
      final outer = center + Offset(radius * 1.9 * math.cos(angle), radius * 1.9 * math.sin(angle));
      canvas.drawLine(center, outer, rayPaint..strokeWidth = 3);
    }

    // Ribbon tails.
    final ribbonPaint = Paint()..color = LaarishColors.tomato;
    final tailW = size.width * 0.1;
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - tailW, center.dy + radius * 0.6)
        ..lineTo(center.dx - tailW * 1.6, size.height)
        ..lineTo(center.dx - tailW * 0.3, size.height - tailW)
        ..lineTo(center.dx, center.dy + radius * 0.6)
        ..close(),
      ribbonPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + tailW, center.dy + radius * 0.6)
        ..lineTo(center.dx + tailW * 1.6, size.height)
        ..lineTo(center.dx + tailW * 0.3, size.height - tailW)
        ..lineTo(center.dx, center.dy + radius * 0.6)
        ..close(),
      ribbonPaint,
    );

    // Medallion.
    canvas.drawCircle(center, radius, Paint()..color = LaarishColors.sunflowerDeep);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = LaarishColors.sunflower
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(center, radius * 0.68, Paint()..color = Colors.white.withValues(alpha: 0.9));

    // Star at center.
    final path = Path();
    const points = 5;
    final starRadius = radius * 0.42;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? starRadius : starRadius * 0.45;
      final angle = (math.pi / points) * i - math.pi / 2;
      final p = center + Offset(r * math.cos(angle), r * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = LaarishColors.sunflowerDeep);
  }

  @override
  bool shouldRepaint(covariant _GoldSealPainter oldDelegate) => oldDelegate.shine != shine;
}
