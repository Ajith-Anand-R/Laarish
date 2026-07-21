import 'package:flutter/material.dart';
import '../theme/laarish_colors.dart';
import '../theme/laarish_spacing.dart';
import '../theme/laarish_text.dart';
import 'laarish_button.dart';
import 'sticker_card.dart';

/// Phase-0 placeholder for a screen not yet built by its workstream
/// (PARALLEL_AGENTS.md). Themed, not raw Material chrome, so the app is
/// walkable end-to-end while WS1-WS7 fill in the real experience.
class StubScreen extends StatelessWidget {
  const StubScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.continueLabel,
    required this.onContinue,
    this.accent = LaarishColors.sunflowerDeep,
  });

  final String title;
  final String subtitle;
  final String continueLabel;
  final VoidCallback onContinue;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaarishColors.paper,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(LaarishSpacing.lg),
            child: StickerCard(
              padding: const EdgeInsets.all(LaarishSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: LaarishText.display28, textAlign: TextAlign.center),
                  const SizedBox(height: LaarishSpacing.sm),
                  Text(
                    subtitle,
                    style: LaarishText.body16.copyWith(color: LaarishColors.soil),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: LaarishSpacing.xl),
                  LaarishButton(label: continueLabel, color: accent, onTap: onContinue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
