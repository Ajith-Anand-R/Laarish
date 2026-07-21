import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../content/models/level_content.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/mascot_view.dart';
import '../../core/widgets/speech_bubble.dart';
import '../../core/widgets/sticker_card.dart';
import 'minigames/minigame_common.dart';

/// mascotIntro — speech-bubble sequence cycling through `lines`, tap to
/// advance. `step.rive` names the future Rive artboard; today we draw an
/// on-brand blob stand-in (AGENT.md CRITICAL CONSTRAINT — no art assets yet).
class MascotIntroStep extends StatefulWidget {
  const MascotIntroStep({super.key, required this.step, required this.plantId, required this.color, required this.onDone});
  final LevelStep step;
  final String plantId;
  final Color color;
  final VoidCallback onDone;

  @override
  State<MascotIntroStep> createState() => _MascotIntroStepState();
}

class _MascotIntroStepState extends State<MascotIntroStep> {
  int _i = 0;

  void _next() {
    HapticFeedback.selectionClick();
    if (_i < widget.step.lines.length - 1) {
      setState(() => _i++);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.step.lines;
    return GestureDetector(
      onTap: _next,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MascotView.plant(
            widget.plantId,
            size: 190,
            glow: true,
            energy: mascotEnergy(widget.plantId),
          ),
          const SizedBox(height: 16),
          SpeechBubble(text: lines.isEmpty ? '' : lines[_i]),
          const SizedBox(height: 8),
          Text('Tap to continue', style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
        ],
      ),
    );
  }
}

/// lesson — a sticker card with `prompt` text and a "Got it!" button.
class LessonStep extends StatelessWidget {
  const LessonStep({super.key, required this.step, required this.color, required this.onDone});
  final LevelStep step;
  final Color color;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      color: LaarishColors.paperDeep,
      padding: const EdgeInsets.all(LaarishSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BiomeBlob(color: color, icon: Icons.menu_book_rounded, size: 90),
          const SizedBox(height: 16),
          Text(step.prompt ?? '', style: LaarishText.body18, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          LaarishButton(label: 'Got it!', color: color, onTap: onDone),
        ],
      ),
    );
  }
}

/// quiz — tappable cards with a subtle 3D tilt feel; correct triggers a
/// bloom animation and continue; wrong shows gentle encouragement + retry
/// (AGENT.md "no failure states" — never locks the child out).
class QuizStep extends StatefulWidget {
  const QuizStep({super.key, required this.step, required this.color, required this.onDone});
  final LevelStep step;
  final Color color;
  final VoidCallback onDone;

  @override
  State<QuizStep> createState() => _QuizStepState();
}

class _QuizStepState extends State<QuizStep> {
  int? _selected;
  bool _correct = false;
  bool _wrong = false;

  void _tap(int i) {
    setState(() {
      _selected = i;
      _correct = i == widget.step.quizAnswer;
      _wrong = !_correct;
    });
    if (_correct) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.step.quizOptions;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.step.quizQuestion ?? '', style: LaarishText.display22, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [for (var i = 0; i < options.length; i++) _optionCard(i, options[i])],
        ),
        const SizedBox(height: 16),
        if (_wrong)
          Text('Not quite — try again!', style: LaarishText.body16.copyWith(color: widget.color))
        else if (_correct)
          Column(
            children: [
              Text('Yes! 🌱', style: LaarishText.display22)
                  .animate()
                  .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: Curves.easeOutBack, duration: 400.ms),
              const SizedBox(height: 12),
              LaarishButton(label: 'Continue', color: widget.color, onTap: widget.onDone),
            ],
          ),
      ],
    );
  }

  Widget _optionCard(int i, String text) {
    final isRightPick = _correct && _selected == i;
    final isWrongPick = _wrong && _selected == i;
    return JuicyTap(
      enabled: !_correct,
      onTap: () => _tap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: isRightPick
              ? LaarishColors.leaf.withValues(alpha: 0.4)
              : (isWrongPick ? widget.color.withValues(alpha: 0.15) : Colors.white),
          border: Border.all(color: widget.color, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(text, style: LaarishText.body18, textAlign: TextAlign.center),
      ),
    );
  }
}

/// realTask — "do it for real with your kit" + confirm button. When
/// `confirm == 'photoOptional'`, also shows a skippable photo-attach button
/// (image_picker isn't installed yet — see WS3 handoff request).
class RealTaskStep extends StatefulWidget {
  const RealTaskStep({super.key, required this.step, required this.color, required this.onDone});
  final LevelStep step;
  final Color color;
  final VoidCallback onDone;

  @override
  State<RealTaskStep> createState() => _RealTaskStepState();
}

class _RealTaskStepState extends State<RealTaskStep> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BiomeBlob(color: widget.color, icon: Icons.yard_rounded, size: 100),
        const SizedBox(height: 16),
        Text(
          widget.step.prompt ?? 'Now do it for real with your kit!',
          style: LaarishText.body18,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        if (!_done) ...[
          LaarishButton(
            label: "I did it with my kit!",
            color: widget.color,
            onTap: () {
              setState(() => _done = true);
              widget.onDone();
            },
          ),
          if (widget.step.confirm == 'photoOptional') ...[
            const SizedBox(height: 12),
            TextButton(
              // TODO(Foundation dep request): wire real capture once
              // image_picker is added to pubspec.yaml (not installed today —
              // see WS3 handoff "Requests for Foundation"). Skippable no-op
              // for now so the flow never blocks a child.
              onPressed: () {},
              child: Text('Attach photo (coming soon)', style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
            ),
          ],
        ] else
          Text('Saved!', style: LaarishText.body16),
      ],
    );
  }
}
