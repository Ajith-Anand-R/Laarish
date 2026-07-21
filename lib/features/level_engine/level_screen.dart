import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../core/fx/fx.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/mascot_view.dart';
import '../../core/widgets/ribbon_banner.dart';
import '../../core/widgets/shader_view.dart';
import '../../core/widgets/sticker_card.dart';

/// Tapping a level plays a video lesson. The level is only marked complete —
/// and the next unlocked — once the child has watched the video through to the
/// end (ARCHITECTURE.md §3.4 completion path via `applyLevelReward`).
///
/// Visually this is the app's cinema. The stack, back to front:
///   1. `level_bg.frag` — volumetric aurora + caustics, tinted to the biome
///      (fails soft to an animated mesh gradient, which is itself alive);
///   2. a blurred biome photo plate at low opacity for texture;
///   3. depth-parallax scenery bands that lean with the device;
///   4. an ambient particle field (pollen / embers by biome);
///   5. the lesson card itself, a 3D object you can turn with your finger,
///      wearing an animated aurora rim while the lesson is still gated;
///   6. burst/shake/haptic payoff on completion.
///
/// Constructor is frozen: router.dart builds
/// `LevelScreen(plantId: …, level: …)` — do not change this signature.
class LevelScreen extends ConsumerStatefulWidget {
  const LevelScreen({super.key, required this.plantId, required this.level});

  final String plantId;
  final int level;

  @override
  ConsumerState<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends ConsumerState<LevelScreen> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _watched = false;
  bool _completing = false;
  final _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // mock: single placeholder video until per-level clips ship
    final c = VideoPlayerController.asset('assets/video/story.mp4');
    try {
      await c.initialize();
      c.addListener(_tick);
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() => _controller = c);
      c.play();
    } catch (_) {
      // Asset missing on this build — fail soft to a "coming soon" card.
      c.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  void _tick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    // End-gate: enable "continue" only once playback reaches the end.
    // Seeking backward to rewatch is fine; forward scrubbing is disabled.
    if (!_watched &&
        c.value.duration > Duration.zero &&
        c.value.position >= c.value.duration) {
      setState(() => _watched = true);
      // The gate opening is an event, not a state change — celebrate it.
      if (mounted) {
        ShakeScope.go(context, intensity: 5, haptic: HapticImpact.light);
        FxBurst.atWidget(
          _cardKey,
          color: LaarishColors.biome[widget.plantId] ?? LaarishColors.leaf,
          style: BurstStyle.sparkle,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_tick);
    _controller?.dispose();
    super.dispose();
  }

  /// Video watched → hand off to the checkpoint (photo upload + verification +
  /// quiz). The reward and the unlock of the next level happen there, only
  /// after the child proves they took in the lesson.
  void _complete() {
    if (_completing) return;
    setState(() => _completing = true);

    // Impact first, state second — the payoff must land on the tap frame.
    ShakeScope.go(context, intensity: 12, haptic: HapticImpact.heavy);
    FxBurst.atWidget(
      _cardKey,
      color: LaarishColors.biome[widget.plantId] ?? LaarishColors.leaf,
      style: BurstStyle.celebrate,
      intensity: 1.2,
    );

    context.go('/checkpoint/${widget.plantId}/${widget.level}');
  }

  @override
  Widget build(BuildContext context) {
    final biome = LaarishColors.biome[widget.plantId] ?? LaarishColors.leafDeep;
    return Scaffold(
      backgroundColor: LaarishColors.paper,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _CinematicBackdrop(plantId: widget.plantId, biome: biome),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(LaarishSpacing.lg),
              child: Center(child: _body(biome)),
            ),
          ),
          // Exit affordance floats above the scene on frosted glass.
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(LaarishSpacing.sm),
                child: _GlassIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.go('/map'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(Color biome) {
    final c = _controller;

    if (_failed) return _comingSoonCard(biome);

    if (c == null || !c.value.isInitialized) return _LoadingBloom(color: biome);

    return SingleChildScrollView(
      child: SpringIn(
        from: const Offset(0, 40),
        beginScale: 0.86,
        child: StickerCard(
          key: _cardKey,
          tilt: true,
          elevation: 2,
          glow: _watched ? biome : null,
          padding: const EdgeInsets.all(LaarishSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RibbonBanner(
                text: '${widget.plantId} · level ${widget.level}',
                color: biome,
              ),
              const SizedBox(height: LaarishSpacing.lg),
              _CinemaFrame(controller: c, biome: biome),
              const SizedBox(height: LaarishSpacing.sm),
              // Forward scrubbing disabled so the end-gate can't be skipped.
              _LiquidProgress(controller: c, color: biome),
              const SizedBox(height: LaarishSpacing.lg),
              LaarishButton(
                label: 'Mark complete & continue',
                color: biome,
                icon: Icons.check_rounded,
                hero: _watched,
                enabled: _watched && !_completing,
                onTap: _complete,
              ),
              if (!_watched) ...[
                const SizedBox(height: LaarishSpacing.sm),
                Text(
                  'Watch to the end to continue',
                  style: LaarishText.body16.copyWith(color: LaarishColors.soil),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Fail-soft card shown when the placeholder video can't be initialised —
  /// the child can still finish the level via the same completion path.
  Widget _comingSoonCard(Color biome) {
    return SpringIn(
      child: StickerCard(
        key: _cardKey,
        tilt: true,
        elevation: 2,
        glow: biome,
        padding: const EdgeInsets.all(LaarishSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RibbonBanner(
              text: '${widget.plantId} · level ${widget.level}',
              color: biome,
            ),
            const SizedBox(height: LaarishSpacing.lg),
            MascotView.plant(
              widget.plantId,
              size: 120,
              glow: true,
              energy: mascotEnergy(widget.plantId),
            ),
            const SizedBox(height: LaarishSpacing.sm),
            Text('Lesson video coming soon',
                style: LaarishText.display22, textAlign: TextAlign.center),
            const SizedBox(height: LaarishSpacing.sm),
            Text(
              "We're filming this one! You can still finish the level.",
              style: LaarishText.body16,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LaarishSpacing.lg),
            LaarishButton(
              label: 'Mark as watched',
              color: biome,
              icon: Icons.check_rounded,
              hero: true,
              enabled: !_completing,
              onTap: _complete,
            ),
          ],
        ),
      ),
    );
  }
}

/// The living scene behind the lesson: GPU shader → blurred biome plate →
/// depth-parallax scenery → particles. Each layer is its own
/// [RepaintBoundary] so the animated ones never dirty the static ones.
class _CinematicBackdrop extends StatelessWidget {
  const _CinematicBackdrop({required this.plantId, required this.biome});

  final String plantId;
  final Color biome;

  @override
  Widget build(BuildContext context) {
    // Ember air for the hot biomes, drifting pollen for the leafy ones.
    final hot = plantId == 'chilly' || plantId == 'tommy';

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: ShaderView(
            asset: 'shaders/level_bg.frag',
            extraFloats: [biome.r, biome.g, biome.b],
            // Fail-soft is itself animated — a device without shader support
            // still gets a moving scene, never a flat colour.
            fallback: AnimatedMeshGradient(
              colors: [
                Color.lerp(biome, Colors.black, 0.42)!,
                biome,
                Color.lerp(biome, LaarishColors.sunflower, 0.5)!,
                Color.lerp(biome, Colors.white, 0.55)!,
              ],
            ),
          ),
        ),
        // Biome photo plate, blurred and dimmed — texture, not subject.
        Positioned.fill(
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Opacity(
                opacity: 0.28,
                child: Image.asset(
                  'assets/images/biome_$plantId.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
        // Diorama depth: three silhouette bands that separate as the device
        // tilts, so the scene has real z-space behind the card.
        IgnorePointer(
          child: DepthStack(
            amount: 22,
            layers: [
              _SceneryBand(
                color: Color.lerp(biome, Colors.black, 0.55)!.withValues(alpha: 0.35),
                height: 0.30,
                bump: 0.10,
              ),
              _SceneryBand(
                color: Color.lerp(biome, Colors.black, 0.68)!.withValues(alpha: 0.45),
                height: 0.20,
                bump: 0.14,
              ),
              _SceneryBand(
                color: Color.lerp(biome, Colors.black, 0.80)!.withValues(alpha: 0.55),
                height: 0.12,
                bump: 0.18,
              ),
            ],
          ),
        ),
        RepaintBoundary(
          child: ParticleField(
            color: hot
                ? LaarishColors.chiliFlame
                : Color.lerp(LaarishColors.sunflower, Colors.white, 0.4)!,
            style: hot ? ParticleStyle.ember : ParticleStyle.pollen,
            count: 30,
            speed: hot ? 1.6 : 0.9,
            opacity: 0.5,
          ),
        ),
        // Readability scrim — keeps card text legible over any scene without
        // flattening the colour underneath it.
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.0,
                colors: [Color(0x66FDF6E7), Color(0x00FDF6E7)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One rolling silhouette hill anchored to the bottom of the screen.
class _SceneryBand extends StatelessWidget {
  const _SceneryBand({
    required this.color,
    required this.height,
    required this.bump,
  });

  final Color color;

  /// Fraction of screen height the band occupies.
  final double height;

  /// Hill amplitude as a fraction of the band height.
  final double bump;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: height,
        widthFactor: 1.25, // overscan so tilt drift never exposes an edge
        child: CustomPaint(
          painter: _HillPainter(color: color, bump: bump),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _HillPainter extends CustomPainter {
  _HillPainter({required this.color, required this.bump});

  final Color color;
  final double bump;

  @override
  void paint(Canvas canvas, Size size) {
    final a = size.height * bump * 3;
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, a * 1.2);
    // Two arcs make a lumpy horizon; flat-topped hills read as UI, not scenery.
    path.quadraticBezierTo(size.width * 0.28, -a * 0.4, size.width * 0.52, a * 0.9);
    path.quadraticBezierTo(size.width * 0.78, a * 2.0, size.width, a * 0.2);
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HillPainter old) =>
      old.color != color || old.bump != bump;
}

/// The video, framed like a cinema screen: rounded bezel, inner shadow, a
/// glass play button that breathes, and a soft coloured bloom bleeding out of
/// the frame edges the way a real backlit panel does.
class _CinemaFrame extends StatelessWidget {
  const _CinemaFrame({required this.controller, required this.biome});

  final VideoPlayerController controller;
  final Color biome;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (context, value, _) {
        final playing = value.isPlaying;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              // Screen bloom — the panel lights the card around it.
              BoxShadow(
                color: biome.withValues(alpha: playing ? 0.45 : 0.2),
                blurRadius: 30,
                spreadRadius: -4,
              ),
              ...DepthShadow.shadows(LaarishColors.soil, 1.2),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: value.aspectRatio,
              child: GestureDetector(
                onTap: () => playing ? c.pause() : c.play(),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(c),
                    // Inner vignette so the frame edges feel recessed.
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            radius: 0.9,
                            colors: [Color(0x00000000), Color(0x40000000)],
                          ),
                        ),
                      ),
                    ),
                    // Play affordance: fades out while playing, breathes while
                    // paused so a stopped video always invites a tap.
                    AnimatedOpacity(
                      opacity: playing ? 0 : 1,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                      child: IgnorePointer(
                        ignoring: playing,
                        child: Center(
                          child: PulseGlow(
                            color: Colors.white,
                            radius: 18,
                            intensity: 0.4,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: const Alignment(-0.3, -0.4),
                                  colors: [
                                    Colors.white.withValues(alpha: 0.95),
                                    Colors.white.withValues(alpha: 0.55),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 44,
                                color: biome,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Video progress as a glowing liquid vine rather than a Material bar: a
/// rounded track, a gradient fill, and a bright bead riding the leading edge.
class _LiquidProgress extends StatelessWidget {
  const _LiquidProgress({required this.controller, required this.color});

  final VideoPlayerController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final total = value.duration.inMilliseconds;
        final fraction =
            total <= 0 ? 0.0 : (value.position.inMilliseconds / total).clamp(0.0, 1.0);
        return SizedBox(
          height: 16,
          child: CustomPaint(
            size: Size.infinite,
            painter: _LiquidBarPainter(fraction: fraction, color: color),
          ),
        );
      },
    );
  }
}

class _LiquidBarPainter extends CustomPainter {
  _LiquidBarPainter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.25, size.width, size.height * 0.5),
      r,
    );
    canvas.drawRRect(track, Paint()..color = LaarishColors.paperDeep);

    if (fraction <= 0) return;
    final w = size.width * fraction;
    final fill = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.25, w, size.height * 0.5),
      r,
    );
    canvas.drawRRect(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [Color.lerp(color, Colors.white, 0.45)!, color],
        ).createShader(fill.outerRect),
    );

    // Leading bead + its glow — the eye follows this, not the bar.
    final cx = w.clamp(4.0, size.width - 4.0);
    final cy = size.height / 2;
    canvas.drawCircle(
      Offset(cx, cy),
      size.height * 0.55,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(Offset(cx, cy), size.height * 0.34, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _LiquidBarPainter old) =>
      old.fraction != fraction || old.color != color;
}

/// Loading state as a blooming flower of light instead of a Material spinner.
class _LoadingBloom extends StatefulWidget {
  const _LoadingBloom({required this.color});
  final Color color;

  @override
  State<_LoadingBloom> createState() => _LoadingBloomState();
}

class _LoadingBloomState extends State<_LoadingBloom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _BloomPainter(t: _c.value, color: widget.color),
        ),
      ),
    );
  }
}

class _BloomPainter extends CustomPainter {
  _BloomPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const petals = 6;
    for (var i = 0; i < petals; i++) {
      // Each petal is a phase-shifted pulse, so the ring breathes around.
      final phase = (t + i / petals) % 1.0;
      final scale = 0.35 + 0.65 * Curves.easeInOut.transform(
        phase < 0.5 ? phase * 2 : (1 - phase) * 2,
      );
      final angle = (i / petals) * 2 * 3.14159265 + t * 1.2;
      final pos = c + Offset.fromDirection(angle, 34);
      canvas.drawCircle(
        pos,
        11 * scale,
        Paint()
          ..color = color.withValues(alpha: 0.35 + 0.5 * scale)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.drawCircle(
      c,
      13,
      Paint()..color = LaarishColors.sunflower.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _BloomPainter old) => old.t != t;
}

/// Frosted circular glass button for floating chrome over a live scene.
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MagneticTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: LaarishColors.ink, size: 24),
          ),
        ),
      ),
    );
  }
}
