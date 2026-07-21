import 'package:flutter/material.dart';
import '../../../core/theme/laarish_text.dart';
import 'minigame_common.dart';

/// Generic "tap N times" minigame — backs soak/drop/mist/scatter/pick/count
/// (they differ only in prompt/target/icon/label). Ladder: one shared
/// implementation, six thin wrappers configure it instead of six
/// near-identical widgets.
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

  void _tap() {
    if (_done) return;
    setState(() => _taps++);
    if (_taps >= widget.target) {
      setState(() => _done = true);
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinigamePrompt(text: widget.prompt),
        JuicyTap(
          enabled: !_done,
          onTap: _tap,
          child: BiomeBlob(color: widget.color, icon: widget.icon, size: 110),
        ),
        const SizedBox(height: 16),
        Text(
          _done ? widget.completeLabel : '${_taps.clamp(0, widget.target)} / ${widget.target}',
          style: LaarishText.display22,
        ),
      ],
    );
  }
}
