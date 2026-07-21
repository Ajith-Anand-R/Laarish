import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../content/models/level_content.dart';
import '../../core/audio/audio_service.dart';
import '../../core/fx/fx.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/sticker_card.dart';
import '../../domain/reward_table.dart';
import '../../domain/unlock_policy.dart';
import '../rewards/reward_overlay.dart';
import 'interaction_dispatcher.dart';
import 'level_reward_logic.dart';
import 'progress_steps.dart';
import 'step_widgets.dart';
import 'vine_progress.dart';

/// Finite-state machine over `LevelContent.steps` (ARCHITECTURE.md §3.3).
/// One widget drives all 20 levels — new plants/levels are new JSON only
/// (AGENT.md directive 7).
///
/// Motion pass: advancing a step is a **camera move**, not a rebuild. The
/// outgoing card rotates away into depth while the incoming one swings in and
/// overshoots ([DepthSwapper]); the vine springs forward; a spark fires at the
/// card and a light haptic lands on the same frame. Reaching `reward` shakes
/// the whole world.
class LevelRunner extends ConsumerStatefulWidget {
  const LevelRunner({super.key, required this.content, required this.plantId, required this.level});
  final LevelContent content;
  final String plantId;
  final int level;

  @override
  ConsumerState<LevelRunner> createState() => _LevelRunnerState();
}

class _LevelRunnerState extends ConsumerState<LevelRunner> {
  int _index = 0;
  bool _rewardTriggered = false;
  final _cardKey = GlobalKey();

  void _advance() {
    if (_index < widget.content.steps.length - 1) {
      final color = LaarishColors.biome[widget.plantId] ?? LaarishColors.leafDeep;
      // Payoff for finishing a step: spark at the card, a nudge, a pop sfx.
      FxBurst.atWidget(_cardKey, color: color, style: BurstStyle.pop, intensity: 0.7);
      ShakeScope.go(context, intensity: 4, haptic: HapticImpact.light);
      AudioService.instance.play(Sfx.pop);
      setState(() {
        _index++;
        _rewardTriggered = false;
      });
    }
  }

  Future<void> _handleReward(LevelStep step) async {
    if (_rewardTriggered) return;
    _rewardTriggered = true;
    final color = LaarishColors.biome[widget.plantId] ?? LaarishColors.leafDeep;
    // The level is done — hit it hard before any state or navigation work.
    ShakeScope.go(context, intensity: 14, haptic: HapticImpact.heavy);
    FxBurst.atWidget(_cardKey, color: color, style: BurstStyle.celebrate, intensity: 1.3);

    final bundle = RewardBundle(sunPoints: step.sunPoints, seedCoins: step.seedCoins);
    await ref.read(gameSaveProvider.notifier).mutate(
          (save) => applyLevelReward(save, plantId: widget.plantId, level: widget.level, bundle: bundle),
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
    final color = LaarishColors.biome[widget.plantId] ?? LaarishColors.leafDeep;
    final step = widget.content.steps[_index];

    if (step.type == 'reward') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleReward(step));
    }

    return Column(
      children: [
        VineProgress(done: _index, total: widget.content.steps.length, color: color),
        const SizedBox(height: LaarishSpacing.lg),
        Expanded(
          child: SingleChildScrollView(
            // The burst anchor sits OUTSIDE the swapper: during a transition
            // the swapper holds both the outgoing and incoming card at once,
            // so a GlobalKey inside it would be duplicated in the tree.
            child: KeyedSubtree(
              key: _cardKey,
              child: Center(
                child: DepthSwapper(
                  // Key by step index so every advance is a real page turn.
                  child: StickerCard(
                    key: ValueKey(_index),
                    elevation: 1.6,
                    padding: const EdgeInsets.all(LaarishSpacing.xl),
                    child: _buildStep(step, color),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(LevelStep step, Color color) {
    switch (step.type) {
      case 'mascotIntro':
        return MascotIntroStep(step: step, plantId: widget.plantId, color: color, onDone: _advance);
      case 'lesson':
        return LessonStep(step: step, color: color, onDone: _advance);
      case 'interaction':
        return buildMinigame(step: step, plantId: widget.plantId, color: color, onComplete: _advance);
      case 'realTask':
        return RealTaskStep(step: step, color: color, onDone: _advance);
      case 'video':
        return LevelVideoStep(
          plantId: widget.plantId,
          level: widget.level,
          color: color,
          title: widget.content.title,
          onDone: _advance,
        );
      case 'capture':
        return ProgressCaptureStep(
          plantId: widget.plantId,
          level: widget.level,
          color: color,
          prompt: step.prompt ?? '',
          onDone: _advance,
        );
      case 'quiz':
        return QuizStep(step: step, color: color, onDone: _advance);
      case 'reward':
        return SizedBox(
          height: 120,
          child: Center(
            child: Text('Collecting your reward…', style: LaarishText.body18),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
