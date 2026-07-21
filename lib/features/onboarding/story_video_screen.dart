import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/ribbon_banner.dart';
import '../../core/widgets/sticker_card.dart';

/// S6 — video_player in a decorated frame. `assets/video/story.mp4` doesn't
/// exist yet (no video assets shipped), so init is wrapped in try/catch and
/// falls back to a themed "coming soon" placeholder — same pattern as
/// AudioService/LevelScreen's missing-asset fallbacks, never crashes.
///
/// Skip-after-first-watch is a simple local (non-persisted) bool for now —
/// a real "already saw onboarding" flag is a GameSave/ProgressRepository
/// schema change and repositories.dart is frozen (see handoff note).
class StoryVideoScreen extends StatefulWidget {
  const StoryVideoScreen({super.key});

  @override
  State<StoryVideoScreen> createState() => _StoryVideoScreenState();
}

class _StoryVideoScreenState extends State<StoryVideoScreen> {
  VideoPlayerController? _controller;
  bool _videoFailed = false;
  bool _hasWatchedOnce = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final controller = VideoPlayerController.asset('assets/video/story.mp4');
    try {
      await controller.initialize();
      controller.addListener(_onTick);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      controller.play(); // intro auto-plays right after "I'm an Agriculturist"
    } catch (_) {
      // No asset shipped yet (WS7) — themed placeholder instead of a crash.
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (!_hasWatchedOnce && c.value.position >= c.value.duration && c.value.duration > Duration.zero) {
      setState(() => _hasWatchedOnce = true);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  bool get _canContinue => _videoFailed || _hasWatchedOnce;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaarishColors.paper,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(LaarishSpacing.lg),
              child: Column(
                children: [
                  const RibbonBanner(text: 'Why We Grow', color: LaarishColors.sunflowerDeep),
                  const SizedBox(height: LaarishSpacing.lg),
                  Expanded(
                    child: Center(
                      child: StickerCard(
                        padding: const EdgeInsets.all(LaarishSpacing.md),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(LaarishSpacing.md),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildFrameContent(),
                                // Filmic vignette darkens the frame edges.
                                const IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        radius: 0.9,
                                        colors: [Colors.transparent, Color(0x59000000)],
                                        stops: [0.62, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 550.ms)
                        .slideY(begin: 0.14, end: 0, delay: 300.ms, curve: Curves.easeOutCubic),
                  ),
                  const SizedBox(height: LaarishSpacing.lg),
                  Text(
                    _videoFailed
                        ? "Our story is still being filmed — come back soon!"
                        : (_hasWatchedOnce ? 'Great watching!' : 'Watch the whole story to continue'),
                    style: LaarishText.body16,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: LaarishSpacing.md),
                  Opacity(
                    opacity: _canContinue ? 1 : 0.4,
                    child: IgnorePointer(
                      ignoring: !_canContinue,
                      child: LaarishButton(
                        label: _canContinue ? 'Continue' : 'Watching…',
                        color: LaarishColors.sunflowerDeep,
                        onTap: () => context.go('/intro'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Cinematic letterbox bars sweep in from the screen edges on entry.
          Align(
            alignment: Alignment.topCenter,
            child: Container(height: 28, color: Colors.black)
                .animate()
                .slideY(begin: -1, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(height: 28, color: Colors.black)
                .animate()
                .slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameContent() {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(controller),
          GestureDetector(
            onTap: () => setState(() {
              controller.value.isPlaying ? controller.pause() : controller.play();
            }),
            child: AnimatedOpacity(
              opacity: controller.value.isPlaying ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white),
            ),
          ),
        ],
      );
    }
    if (_videoFailed) {
      // Keep the fail-soft placeholder, but give it a slow filmic shimmer sweep
      // so a missing asset still feels like an intentional "coming soon" card.
      return Container(
        color: LaarishColors.paperDeep,
        alignment: Alignment.center,
        child: const Icon(Icons.movie_creation_rounded, size: 56, color: LaarishColors.soil),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 2000.ms,
            color: Colors.white.withValues(alpha: 0.35),
          );
    }
    return const Center(child: CircularProgressIndicator());
  }
}
