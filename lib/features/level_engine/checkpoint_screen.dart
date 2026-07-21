import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../content/journey.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../domain/reward_table.dart';
import '../../domain/unlock_policy.dart';
import '../rewards/reward_overlay.dart';
import 'level_reward_logic.dart';

/// The gate between watching a level's video and unlocking the next one:
///   1. the child photographs their real plant / kit work,
///   2. the photo is verified,
///   3. a one-question quiz confirms they picked up the lesson.
/// Only when the quiz is answered correctly is the reward granted and the
/// next level opened.
///
/// ponytail: photo "verification" is a stub that accepts any captured image —
/// there's no vision backend yet. Swap the `_verified = true` line for a real
/// check (on-device model or upload) when one exists.
class CheckpointScreen extends ConsumerStatefulWidget {
  const CheckpointScreen({super.key, required this.plantId, required this.level});

  final String plantId;
  final int level;

  @override
  ConsumerState<CheckpointScreen> createState() => _CheckpointScreenState();
}

enum _Phase { photo, review, quiz }

class _CheckpointScreenState extends ConsumerState<CheckpointScreen> {
  _Phase _phase = _Phase.photo;
  String? _photoPath;
  int? _picked; // selected quiz option
  bool _wrong = false;
  bool _finishing = false;

  Color get _biome => LaarishColors.biome[widget.plantId] ?? LaarishColors.leafDeep;
  QuizQuestion get _q => levelQuiz[(widget.level - 1).clamp(0, levelQuiz.length - 1)];

  Future<void> _takePhoto() async {
    final path = await ref.read(photoPickerProvider)();
    if (path == null || !mounted) return; // child backed out
    setState(() {
      _photoPath = path;
      _phase = _Phase.review;
    });
  }

  void _verify() {
    // Stub verification — accept the captured photo. See class doc.
    setState(() => _phase = _Phase.quiz);
  }

  void _answer(int i) {
    if (_finishing) return;
    if (i == _q.answer) {
      setState(() {
        _picked = i;
        _wrong = false;
      });
      _finish();
    } else {
      setState(() {
        _picked = i;
        _wrong = true;
      });
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    const bundle = RewardBundle(sunPoints: 20, seedCoins: 5);
    await ref.read(gameSaveProvider.notifier).mutate((save) {
      final next = applyLevelReward(
        save,
        plantId: widget.plantId,
        level: widget.level,
        bundle: bundle,
      );
      final photo = _photoPath;
      if (photo != null) next.plants[widget.plantId]?.photos.add(photo);
      return next;
    });
    if (!mounted) return;
    await showRewardOverlay(context, bundle);
    if (!mounted) return;
    final next = UnlockPolicy.nextLevel(widget.plantId, widget.level);
    // Mid-plant → straight to the next level. Level 5 done → the plant's own
    // harvest-reward celebration (which then routes on to /map or /certificate).
    context.go(next == null
        ? '/plant-done/${widget.plantId}'
        : '/level/${next.$1}/${next.$2}');
  }

  @override
  Widget build(BuildContext context) {
    final meta = plantMeta[widget.plantId];
    return Scaffold(
      backgroundColor: LaarishColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: LaarishColors.ink,
        elevation: 0,
        title: Text(
          '${meta?.name ?? widget.plantId} · ${levelTitles[(widget.level - 1).clamp(0, 4)]}',
          style: LaarishText.body16.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LaarishSpacing.lg),
          child: switch (_phase) {
            _Phase.photo => _photoStep(),
            _Phase.review => _reviewStep(),
            _Phase.quiz => _quizStep(),
          },
        ),
      ),
    );
  }

  Widget _photoStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/${widget.plantId}_mascot.png',
          width: 140,
          height: 140,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.photo_camera_rounded, size: 88, color: LaarishColors.soil),
        ),
        const SizedBox(height: LaarishSpacing.lg),
        Text('Show us your work!', style: LaarishText.display22, textAlign: TextAlign.center),
        const SizedBox(height: LaarishSpacing.sm),
        Text(
          'Take a photo of your plant or kit for this level so we can check your progress.',
          style: LaarishText.body16.copyWith(color: LaarishColors.soil),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: LaarishSpacing.xl),
        LaarishButton(
          label: 'Take photo',
          color: _biome,
          icon: Icons.camera_alt_rounded,
          hero: true,
          onTap: _takePhoto,
        ),
      ],
    );
  }

  Widget _reviewStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 220,
            height: 220,
            child: _photoPath == null
                ? const ColoredBox(color: LaarishColors.paperDeep)
                : Image.file(
                    File(_photoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: LaarishColors.paperDeep,
                      child: Icon(Icons.image_rounded, size: 64, color: LaarishColors.soil),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: LaarishSpacing.lg),
        Text('Nice shot! 🌱', style: LaarishText.display22),
        const SizedBox(height: LaarishSpacing.sm),
        Text(
          "Let's verify it and take a quick question.",
          style: LaarishText.body16.copyWith(color: LaarishColors.soil),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: LaarishSpacing.xl),
        LaarishButton(
          label: 'Verify & continue',
          color: _biome,
          icon: Icons.verified_rounded,
          hero: true,
          onTap: _verify,
        ),
        const SizedBox(height: LaarishSpacing.sm),
        TextButton(
          onPressed: _takePhoto,
          child: Text('Retake', style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
        ),
      ],
    );
  }

  Widget _quizStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: LaarishSpacing.md),
          Text('Quick check', style: LaarishText.display22, textAlign: TextAlign.center),
          const SizedBox(height: LaarishSpacing.lg),
          Text(_q.prompt, style: LaarishText.body16.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: LaarishSpacing.lg),
          for (var i = 0; i < _q.options.length; i++) ...[
            _QuizOption(
              label: _q.options[i],
              selected: _picked == i,
              correct: _picked == i && i == _q.answer,
              wrong: _picked == i && _wrong,
              biome: _biome,
              onTap: () => _answer(i),
            ),
            const SizedBox(height: LaarishSpacing.sm),
          ],
          if (_wrong) ...[
            const SizedBox(height: LaarishSpacing.sm),
            Text(
              'Not quite — have another go! 🌼',
              style: LaarishText.body16.copyWith(color: LaarishColors.tomato),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.label,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.biome,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool correct;
  final bool wrong;
  final Color biome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = correct
        ? LaarishColors.leaf
        : wrong
            ? LaarishColors.tomato
            : LaarishColors.paperDeep;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(LaarishSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: LaarishText.body16)),
              if (correct) const Icon(Icons.check_circle_rounded, color: LaarishColors.leaf),
              if (wrong) const Icon(Icons.cancel_rounded, color: LaarishColors.tomato),
            ],
          ),
        ),
      ),
    );
  }
}
