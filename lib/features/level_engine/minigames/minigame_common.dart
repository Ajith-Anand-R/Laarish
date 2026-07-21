import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/motion/laarish_motion.dart';
import '../../../core/theme/laarish_text.dart';
import '../../../core/widgets/mascot_view.dart';

/// Hero prop illustration for a minigame (`assets/images/mg_<game>.png`) — the
/// living, floating object the child is about to interact with. Fails soft to
/// an on-brand blob if that art hasn't shipped.
class MinigamePropHeader extends StatelessWidget {
  const MinigamePropHeader({super.key, required this.game, required this.color});
  final String game;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MascotView(
        asset: 'assets/images/mg_$game.png',
        size: 128,
        color: color,
        energy: 0.7,
      ),
    );
  }
}

/// Shared "juicy" tap wrapper — squash+overshoot feedback + haptic on every
/// tap (DESIGN_SYSTEM.md §4, AGENT.md "silence is a bug"). Reused by all 12
/// minigames instead of each rebuilding tap-press logic (see LaarishButton
/// for the same pattern on plain buttons).
class JuicyTap extends StatefulWidget {
  const JuicyTap({super.key, required this.child, required this.onTap, this.enabled = true});
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<JuicyTap> createState() => _JuicyTapState();
}

class _JuicyTapState extends State<JuicyTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              HapticFeedback.lightImpact();
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? LaarishMotion.tapSquash : 1.0,
        duration: LaarishMotion.tapDown,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Round color-blob placeholder — no character/prop art exists yet
/// (AGENT.md CRITICAL CONSTRAINT), so minigames draw a clean on-brand circle
/// instead of leaving blank space. Swap for Image.asset/Rive later; the
/// `icon` slot stands in for a prop illustration.
class BiomeBlob extends StatelessWidget {
  const BiomeBlob({super.key, required this.color, this.size = 96, this.icon});
  final Color color;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: icon == null ? null : Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

/// Prompt text shown above every minigame — always sourced from
/// `LevelStep.prompt` (content-driven; never a hardcoded canon number).
class MinigamePrompt extends StatelessWidget {
  const MinigamePrompt({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(text, style: LaarishText.body18, textAlign: TextAlign.center),
    );
  }
}

/// Custom rounded progress fill — no raw Material `LinearProgressIndicator`
/// (AGENT.md "no default Material chrome").
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, required this.color, this.width = 160, this.height = 14});
  final double value; // 0..1
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(height / 2)),
        ),
      ),
    );
  }
}
