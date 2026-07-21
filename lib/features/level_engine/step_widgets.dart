import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../content/models/level_content.dart';
import '../../core/audio/audio_service.dart';
import '../../core/fx/fx.dart';
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
///
/// Each line lands as an event: the bubble swaps with a depth push, the
/// mascot does a little acknowledge-pop, and a selection haptic fires.
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
    AudioService.instance.play(Sfx.pop);
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
          // The mascot pops each time the line changes — it "reacts" to its
          // own dialogue instead of standing still through the scene.
          PopOnChange(
            value: _i,
            scale: 1.12,
            child: MascotView.plant(
              widget.plantId,
              size: 190,
              glow: true,
              energy: mascotEnergy(widget.plantId),
            ),
          ),
          const SizedBox(height: 16),
          DepthSwapper(
            duration: const Duration(milliseconds: 340),
            child: SpeechBubble(
              key: ValueKey(_i),
              text: lines.isEmpty ? '' : lines[_i],
            ),
          ),
          const SizedBox(height: 8),
          // A breathing hint — never a static instruction.
          _TapHint(color: widget.color),
        ],
      ),
    );
  }
}

/// Pulsing "tap to continue" affordance: a chevron that bobs and a label that
/// fades in and out, so the screen always tells the child what to do next.
class _TapHint extends StatefulWidget {
  const _TapHint({required this.color});
  final Color color;

  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(
          _c.value < 0.5 ? _c.value * 2 : (1 - _c.value) * 2,
        );
        return Opacity(
          opacity: 0.45 + 0.55 * t,
          child: Transform.translate(
            offset: Offset(0, -4 * t),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tap to continue',
                  style: LaarishText.body16.copyWith(color: LaarishColors.soil),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: widget.color, size: 22),
              ],
            ),
          ),
        );
      },
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
      child: ChainReveal(
        axis: Axis.vertical,
        gap: const Duration(milliseconds: 110),
        spacing: 16,
        children: [
          BiomeBlob(color: color, icon: Icons.menu_book_rounded, size: 90),
          Text(step.prompt ?? '', style: LaarishText.body18, textAlign: TextAlign.center),
          LaarishButton(label: 'Got it!', color: color, hero: true, onTap: onDone),
        ],
      ),
    );
  }
}

/// quiz — tappable cards that live in 3D: they tilt with the device, lift on
/// press, and answer physically. Correct triggers a burst, a screen knock and
/// a chain-revealed continue; wrong gives a gentle head-shake and lets the
/// child try again (AGENT.md "no failure states" — never locks the child out).
class QuizStep extends StatefulWidget {
  const QuizStep({super.key, required this.step, required this.color, required this.onDone});
  final LevelStep step;
  final Color color;
  final VoidCallback onDone;

  @override
  State<QuizStep> createState() => _QuizStepState();
}

class _QuizStepState extends State<QuizStep> with TickerProviderStateMixin {
  int? _selected;
  bool _correct = false;
  bool _wrong = false;

  /// Drives the "nope" head-shake on the wrongly-picked card only.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  final _optionKeys = <int, GlobalKey>{};

  GlobalKey _keyFor(int i) => _optionKeys.putIfAbsent(i, GlobalKey.new);

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _tap(int i) {
    final correct = i == widget.step.quizAnswer;
    setState(() {
      _selected = i;
      _correct = correct;
      _wrong = !correct;
    });

    if (correct) {
      HapticFeedback.heavyImpact();
      AudioService.instance.play(Sfx.sparkle);
      ShakeScope.go(context, intensity: 9, haptic: HapticImpact.none);
      FxBurst.atWidget(
        _keyFor(i),
        color: LaarishColors.leaf,
        style: BurstStyle.shock,
        intensity: 1.1,
      );
    } else {
      HapticFeedback.lightImpact();
      _shake.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.step.quizOptions;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpringIn(
          from: const Offset(0, 18),
          child: Text(
            widget.step.quizQuestion ?? '',
            style: LaarishText.display22,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        // Options cascade in rather than appearing as a block.
        ChainReveal(
          gap: const Duration(milliseconds: 80),
          spacing: 12,
          children: [
            for (var i = 0; i < options.length; i++) _optionCard(i, options[i]),
          ],
        ),
        const SizedBox(height: 16),
        if (_wrong)
          Text('Not quite — try again!',
                  style: LaarishText.body16.copyWith(color: widget.color))
              .animate()
              .fadeIn(duration: 200.ms)
        else if (_correct)
          ChainReveal(
            axis: Axis.vertical,
            spacing: 12,
            gap: const Duration(milliseconds: 140),
            children: [
              Text('Yes! 🌱', style: LaarishText.display28),
              LaarishButton(
                label: 'Continue',
                color: widget.color,
                hero: true,
                onTap: widget.onDone,
              ),
            ],
          ),
      ],
    );
  }

  Widget _optionCard(int i, String text) {
    final isRightPick = _correct && _selected == i;
    final isWrongPick = _wrong && _selected == i;
    // Once answered correctly, the losing cards recede into the background.
    final dimmed = _correct && !isRightPick;

    Widget card = AnimatedContainer(
      key: _keyFor(i),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isRightPick
              ? [
                  Color.lerp(LaarishColors.leaf, Colors.white, 0.55)!,
                  LaarishColors.leaf,
                ]
              : isWrongPick
                  ? [
                      Colors.white,
                      widget.color.withValues(alpha: 0.22),
                    ]
                  : [Colors.white, LaarishColors.paperDeep],
        ),
        border: Border.all(
          color: isRightPick ? LaarishColors.leafDeep : widget.color,
          width: isRightPick ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: DepthShadow.shadows(
          isRightPick ? LaarishColors.leafDeep : LaarishColors.soil,
          isRightPick ? 1.6 : 0.9,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: LaarishText.body18.copyWith(
          color: isRightPick ? Colors.white : LaarishColors.ink,
          fontWeight: isRightPick ? FontWeight.w800 : FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );

    if (isRightPick) {
      card = PulseGlow(
        color: LaarishColors.leaf,
        radius: 18,
        intensity: 0.6,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(18),
        child: card,
      );
    }

    if (isWrongPick) {
      // Decaying horizontal shake — the universal "no" gesture.
      card = AnimatedBuilder(
        animation: _shake,
        child: card,
        builder: (context, child) {
          if (!_shake.isAnimating) return child!;
          final decay = 1 - _shake.value;
          final dx = 10 * decay * (_shake.value * 6 % 2 < 1 ? 1 : -1);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
      );
    }

    card = AnimatedOpacity(
      duration: const Duration(milliseconds: 320),
      opacity: dimmed ? 0.42 : 1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        scale: dimmed ? 0.9 : 1,
        child: card,
      ),
    );

    return Tilt3D(
      maxTilt: 0.20,
      deviceTiltAmount: 0.5,
      liftOnTouch: 1.07,
      onTap: _correct ? null : () => _tap(i),
      child: card,
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
  final _blobKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KeyedSubtree(
          key: _blobKey,
          child: BiomeBlob(color: widget.color, icon: Icons.yard_rounded, size: 100),
        ),
        const SizedBox(height: 16),
        SpringIn(
          from: const Offset(0, 14),
          child: Text(
            widget.step.prompt ?? 'Now do it for real with your kit!',
            style: LaarishText.body18,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        if (!_done) ...[
          LaarishButton(
            label: "I did it with my kit!",
            color: widget.color,
            hero: true,
            icon: Icons.check_rounded,
            onTap: () {
              // Real-world action confirmed — the biggest non-reward moment in
              // a level, so it gets the full treatment.
              ShakeScope.go(context, intensity: 10, haptic: HapticImpact.heavy);
              FxBurst.atWidget(
                _blobKey,
                color: widget.color,
                style: BurstStyle.celebrate,
              );
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
          Text('Saved!', style: LaarishText.body16)
              .animate()
              .scale(begin: const Offset(0.6, 0.6), curve: Curves.easeOutBack),
      ],
    );
  }
}
