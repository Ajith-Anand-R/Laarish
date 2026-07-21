import 'package:flutter/material.dart';
import '../../../content/models/level_content.dart';
import '../../../core/fx/fx.dart';
import '../../../core/theme/laarish_colors.dart';
import '../../../core/theme/laarish_text.dart';
import '../../../core/widgets/laarish_button.dart';
import 'minigame_common.dart';

/// game: "label" — canon labeling convention is "PLANT + date"
/// (CANON.md §1 "Wooden name labels").
///
/// Feel: the tag is a physical object — it hangs slightly crooked, turns in
/// 3D as you tilt the phone, and snaps straight with a pop when you stick it
/// on.
class LabelGame extends StatefulWidget {
  const LabelGame({
    super.key,
    required this.step,
    required this.color,
    required this.plantId,
    required this.onComplete,
  });
  final LevelStep step;
  final Color color;
  final String plantId;
  final VoidCallback onComplete;

  @override
  State<LabelGame> createState() => _LabelGameState();
}

class _LabelGameState extends State<LabelGame> {
  bool _labeled = false;
  final _labelKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = '${widget.plantId.toUpperCase()} · ${now.day}/${now.month}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinigamePrompt(text: widget.step.prompt ?? 'Label your cup!'),
        Tilt3D(
          maxTilt: 0.26,
          deviceTiltAmount: 0.7,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 460),
            curve: Curves.easeOutBack,
            // Hangs crooked until it's stuck on straight.
            turns: _labeled ? 0 : -0.022,
            child: Container(
              key: _labelKey,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, LaarishColors.paperDeep],
                ),
                border: Border.all(color: widget.color, width: 2),
                borderRadius: BorderRadius.circular(10),
                boxShadow: DepthShadow.shadows(LaarishColors.soil, 1.0),
              ),
              child: Text(label, style: LaarishText.display22),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!_labeled)
          LaarishButton(
            label: 'Stick label on',
            color: widget.color,
            hero: true,
            icon: Icons.push_pin_rounded,
            onTap: () {
              setState(() => _labeled = true);
              celebrateMinigame(context, _labelKey, widget.color, big: false);
              widget.onComplete();
            },
          )
        else
          Text('Labeled!', style: LaarishText.body18),
      ],
    );
  }
}
