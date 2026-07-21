import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../app/providers.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/ribbon_banner.dart';
import '../../core/widgets/sticker_card.dart';
import '../../domain/reward_table.dart';
import '../../domain/unlock_policy.dart';
import '../rewards/reward_overlay.dart';
import 'level_reward_logic.dart';

/// Tapping a level plays a video lesson. The level is only marked complete —
/// and the next unlocked — once the child has watched the video through to the
/// end (ARCHITECTURE.md §3.4 completion path via `applyLevelReward`).
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
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_tick);
    _controller?.dispose();
    super.dispose();
  }

  /// Completion path reused from LevelRunner (ARCHITECTURE.md §3.4):
  /// applyLevelReward bumps levelsDone (unlocking the next level via
  /// UnlockPolicy) and credits the wallet, then the shared reward overlay
  /// plays and we return to the map.
  Future<void> _complete() async {
    if (_completing) return;
    setState(() => _completing = true);
    const bundle = RewardBundle(sunPoints: 20, seedCoins: 5);
    await ref.read(gameSaveProvider.notifier).mutate(
          (save) => applyLevelReward(
            save,
            plantId: widget.plantId,
            level: widget.level,
            bundle: bundle,
          ),
        );
    if (!mounted) return;
    await showRewardOverlay(context, bundle);
    if (!mounted) return;
    // Straight into the next level; back to the map only when the journey's done.
    final next = UnlockPolicy.nextLevel(widget.plantId, widget.level);
    context.go(next == null ? '/map' : '/level/${next.$1}/${next.$2}');
  }

  @override
  Widget build(BuildContext context) {
    final biome = LaarishColors.biome[widget.plantId] ?? LaarishColors.leafDeep;
    return Scaffold(
      backgroundColor: LaarishColors.paper,
      body: Stack(
        children: [
          // Soft biome scene backdrop behind a paper scrim so cards stay
          // legible. Fails soft to the flat paper colour.
          Positioned.fill(
            child: Image.asset(
              'assets/images/biome_${widget.plantId}.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(color: LaarishColors.paper),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xE6FDF6E7), Color(0xF2FDF6E7)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(LaarishSpacing.lg),
              child: Center(child: _body(biome)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(Color biome) {
    final c = _controller;

    if (_failed) return _comingSoonCard(biome);

    if (c == null || !c.value.isInitialized) {
      return const CircularProgressIndicator(color: LaarishColors.leaf);
    }

    // Smooth fade-in once the video is ready.
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 400),
      child: SingleChildScrollView(
        child: StickerCard(
          padding: const EdgeInsets.all(LaarishSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RibbonBanner(text: '${widget.plantId} · level ${widget.level}', color: biome),
              const SizedBox(height: LaarishSpacing.lg),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: c.value.aspectRatio,
                  child: GestureDetector(
                    onTap: () => setState(
                        () => c.value.isPlaying ? c.pause() : c.play()),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(c),
                        AnimatedOpacity(
                          opacity: c.value.isPlaying ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 72,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: LaarishSpacing.sm),
              // Forward scrubbing disabled so the end-gate can't be skipped.
              VideoProgressIndicator(
                c,
                allowScrubbing: false,
                padding: const EdgeInsets.symmetric(vertical: LaarishSpacing.sm),
                colors: VideoProgressColors(
                  playedColor: biome,
                  bufferedColor: biome.withValues(alpha: 0.3),
                  backgroundColor: LaarishColors.paperDeep,
                ),
              ),
              const SizedBox(height: LaarishSpacing.lg),
              _continueButton(biome),
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

  /// Gated continue button — greyed and inert until the video reaches the end,
  /// then smoothly fades to full opacity and becomes tappable.
  Widget _continueButton(Color biome) {
    return AnimatedOpacity(
      opacity: _watched ? 1 : 0.4,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_watched || _completing,
        child: LaarishButton(
          label: 'Mark complete & continue',
          color: biome,
          icon: Icons.check_rounded,
          onTap: _complete,
        ),
      ),
    );
  }

  /// Fail-soft card shown when the placeholder video can't be initialised —
  /// the child can still finish the level via the same completion path.
  Widget _comingSoonCard(Color biome) {
    return StickerCard(
      padding: const EdgeInsets.all(LaarishSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RibbonBanner(text: '${widget.plantId} · level ${widget.level}', color: biome),
          const SizedBox(height: LaarishSpacing.lg),
          const Icon(Icons.movie_rounded, size: 56, color: LaarishColors.soil),
          const SizedBox(height: LaarishSpacing.sm),
          Text('Lesson video coming soon', style: LaarishText.display22, textAlign: TextAlign.center),
          const SizedBox(height: LaarishSpacing.sm),
          Text(
            "We're filming this one! You can still finish the level.",
            style: LaarishText.body16,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LaarishSpacing.lg),
          IgnorePointer(
            ignoring: _completing,
            child: LaarishButton(
              label: 'Mark as watched',
              color: biome,
              icon: Icons.check_rounded,
              onTap: _complete,
            ),
          ),
        ],
      ),
    );
  }
}
