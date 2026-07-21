import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/providers.dart';
import '../../core/motion/throttled_ticker.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/ribbon_banner.dart';
import '../../core/widgets/sticker_card.dart';

/// S3 — real mobile_scanner feed with a code-drawn sunflower-petal
/// viewfinder (DESIGN_SYSTEM.md §5). Accepts `laarish://kit/<kitId>`
/// (AGENT.md §3 QR). Manual "I Am an Agriculturist" path is unchanged —
/// both funnel to kitActivated=true, mirroring ProfessionScreen's mutate.
class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({super.key});

  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> with TickerProviderStateMixin {
  MobileScannerController? _controller;
  late final AnimationController _burst;
  late final ThrottledTicker _scanTicker;
  double _scanPhase = 0;
  bool _handled = false;
  bool _cameraFailed = false;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    // Continuous scan-line sweep + corner-bracket pulse — ambient drift, so it
    // rides the throttled 30fps ticker per the perf convention.
    _scanTicker = ThrottledTicker(
      this,
      fps: 30,
      onTick: (elapsed) {
        if (mounted) setState(() => _scanPhase = elapsed.inMilliseconds / 1000);
      },
    )..start();
    try {
      _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
    } catch (_) {
      // No camera / permission denied at construction time — fall back below
      // instead of crashing the onboarding flow (AGENT.md missing-asset rule
      // extends to missing hardware here).
      _cameraFailed = true;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _burst.dispose();
    _scanTicker.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || !value.startsWith('laarish://kit/')) return;
    _handled = true;
    await _controller?.stop();
    if (!mounted) return;
    setState(() {});
    await _burst.forward(from: 0);
    await ref.read(gameSaveProvider.notifier).mutate((save) {
      save.kitActivated = true;
      return save;
    });
    if (mounted) context.go('/intro');
  }

  Future<void> _goManual() async {
    if (mounted) context.go('/profession');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraFailed || _controller == null)
            Container(
              color: LaarishColors.paper,
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(LaarishSpacing.lg),
                child: StickerCard(
                  child: Text(
                    "Camera not available here — use the button below instead!",
                    style: LaarishText.body16,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return Container(
                  color: LaarishColors.paper,
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(LaarishSpacing.lg),
                    child: StickerCard(
                      child: Text(
                        "Camera not available here — use the button below instead!",
                        style: LaarishText.body16,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _PetalViewfinderPainter(phase: _scanPhase),
                size: Size.infinite,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(LaarishSpacing.lg),
              child: Column(
                children: [
                  const RibbonBanner(text: 'Scan Your Laarish Kit', color: LaarishColors.leafDeep),
                  const Spacer(),
                  LaarishButton(
                    label: 'I Am an Agriculturist',
                    color: LaarishColors.sunflowerDeep,
                    onTap: _goManual,
                  ),
                ],
              ),
            ),
          ),
          if (_handled)
            AnimatedBuilder(
              animation: _burst,
              builder: (context, _) => CustomPaint(
                painter: _PetalBurstPainter(progress: _burst.value),
                size: Size.infinite,
              ),
            ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _PetalViewfinderPainter extends CustomPainter {
  _PetalViewfinderPainter({required this.phase});

  /// Seconds-scaled phase driving the scan sweep and bracket pulse.
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    const boxSize = 240.0;
    final box = Rect.fromCenter(center: center, width: boxSize, height: boxSize);

    // Dim everything outside the scan box.
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRRect(RRect.fromRectAndRadius(box, const Radius.circular(24)));
    canvas.drawPath(Path.combine(PathOperation.difference, full, hole), dimPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(24)),
      Paint()
        ..color = LaarishColors.sunflower
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Sweeping scan line with a soft glow trail, bouncing top↔bottom.
    final tri = 1 - (2 * (phase % 1.0) - 1).abs(); // triangle wave 0..1..0
    final y = box.top + boxSize * tri;
    final trail = Rect.fromLTRB(box.left, y - 34, box.right, y);
    canvas.drawRect(
      trail,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00FFC93C), Color(0x4DFFC93C)],
        ).createShader(trail),
    );
    canvas.drawLine(
      Offset(box.left, y),
      Offset(box.right, y),
      Paint()
        ..color = LaarishColors.sunflower
        ..strokeWidth = 2.5,
    );

    // Pulsing corner brackets — the "locked-on" framing feel.
    final pulse = 0.5 + 0.5 * math.sin(phase * 2 * math.pi);
    final len = 22 + pulse * 10;
    final bracket = Paint()
      ..color = LaarishColors.sunflower.withValues(alpha: 0.7 + 0.3 * pulse)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(box.topLeft, box.topLeft.translate(len, 0), bracket);
    canvas.drawLine(box.topLeft, box.topLeft.translate(0, len), bracket);
    canvas.drawLine(box.topRight, box.topRight.translate(-len, 0), bracket);
    canvas.drawLine(box.topRight, box.topRight.translate(0, len), bracket);
    canvas.drawLine(box.bottomLeft, box.bottomLeft.translate(len, 0), bracket);
    canvas.drawLine(box.bottomLeft, box.bottomLeft.translate(0, -len), bracket);
    canvas.drawLine(box.bottomRight, box.bottomRight.translate(-len, 0), bracket);
    canvas.drawLine(box.bottomRight, box.bottomRight.translate(0, -len), bracket);

    // Sunflower petals ringing the viewfinder.
    final petalPaint = Paint()..color = LaarishColors.sunflower.withValues(alpha: 0.9);
    const petals = 14;
    final radius = boxSize / 2 + 6;
    for (var i = 0; i < petals; i++) {
      final angle = (2 * math.pi / petals) * i;
      final p = center.translate(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(angle);
      canvas.drawOval(const Rect.fromLTWH(-5, -12, 10, 20), petalPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalViewfinderPainter oldDelegate) => oldDelegate.phase != phase;
}

class _PetalBurstPainter extends CustomPainter {
  _PetalBurstPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final paint = Paint()..color = LaarishColors.sunflower.withValues(alpha: (1 - progress).clamp(0.0, 1.0));
    const count = 16;
    final r = 260 * Curves.easeOutCubic.transform(progress);
    for (var i = 0; i < count; i++) {
      final angle = (2 * math.pi / count) * i;
      final p = center.translate(math.cos(angle) * r, math.sin(angle) * r);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(angle);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 14, height: 22), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalBurstPainter oldDelegate) => oldDelegate.progress != progress;
}
