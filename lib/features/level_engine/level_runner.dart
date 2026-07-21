import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../content/models/level_content.dart';
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

  void _advance() {
    if (_index < widget.content.steps.length - 1) {
      setState(() {
        _index++;
        _rewardTriggered = false;
      });
    }
  }

  Future<void> _handleReward(LevelStep step) async {
    if (_rewardTriggered) return;
    _rewardTriggered = true;
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
        VineProgress(done: _index, total: widget.content.steps.length),
        const SizedBox(height: LaarishSpacing.lg),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: StickerCard(
                padding: const EdgeInsets.all(LaarishSpacing.xl),
                child: _buildStep(step, color),
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
          child: Center(child: Text('Collecting your reward…', style: LaarishText.body18)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
