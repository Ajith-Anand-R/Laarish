import 'package:flutter/material.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/fx/fx.dart';
import '../../../core/theme/laarish_colors.dart';
import '../../../core/theme/laarish_text.dart';
import 'minigame_common.dart';

/// Generic "tap N times" minigame — backs soak/drop/mist/scatter/pick/count
/// (they differ only in prompt/target/icon/label). Ladder: one shared
/// implementation, six thin wrappers configure it instead of six
/// near-identical widgets.
///
/// Feel: every tap fires a burst at the prop and a haptic, the prop squashes
/// and springs back, the counter punches, and the fill bar creeps toward full.
/// The **last** tap escalates — heavier haptic, celebration burst, a world
/// knock — so the finish is unmistakably different from the taps before it.
/// That escalation is what turns repetition into a chain reaction.
class TapProgressGame extends StatefulWidget {
  const TapProgressGame({
    super.key,
    required this.prompt,
    required this.target,
    required this.color,
    required this.icon,
    required this.onComplete,
    this.completeLabel = 'Nice work!',
  });

  final String prompt;
  final int target;
  final Color color;
  final IconData icon;
  final VoidCallback onComplete;
  final String completeLabel;

  @override
  State<TapProgressGame> createState() => _TapProgressGameState();
}

class _TapProgressGameState extends State<TapProgressGame> {
  int _taps = 0;
  bool _done = false;
  final _propKey = GlobalKey();

  void _tap() {
    if (_done) return;
    final next = _taps + 1;
    final finishing = next >= widget.target;
    setState(() {
      _taps = next;
      _done = finishing;
    });

    if (finishing) {
      AudioService.instance.play(Sfx.sparkle);
      ShakeScope.go(context, intensity: 10, haptic: HapticImpact.heavy);
      FxBurst.atWidget(
        _propKey,
        color: widget.color,
        style: BurstStyle.celebrate,
        intensity: 1.2,
      );
      widget.onComplete();
    } else {
      FxBurst.atWidget(
        _propKey,
        color: widget.color,
        style: BurstStyle.pop,
        // Each tap throws a little more than the last — building pressure.
        intensity: 0.45 + 0.35 * (next / widget.target),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.target <= 0 ? 1.0 : (_taps / widget.target).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinigamePrompt(text: widget.prompt),
        // The prop glows brighter as the goal approaches.
        PulseGlow(
          color: widget.color,
          radius: 10 + 18 * progress,
          intensity: 0.25 + 0.45 * progress,
          child: KeyedSubtree(
            key: _propKey,
            child: JuicyTap(
              enabled: !_done,
              onTap: _tap,
              borderRadius: BorderRadius.circular(999),
              sparkColor: widget.color,
              child: BiomeBlob(color: widget.color, icon: widget.icon, size: 110),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ProgressBar(value: progress, color: widget.color, width: 180),
        const SizedBox(height: 10),
        PopOnChange(
          value: _taps,
          scale: 1.3,
          child: Text(
            _done
                ? widget.completeLabel
                : '${_taps.clamp(0, widget.target)} / ${widget.target}',
            style: LaarishText.display22.copyWith(
              color: _done ? LaarishColors.leafDeep : LaarishColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
