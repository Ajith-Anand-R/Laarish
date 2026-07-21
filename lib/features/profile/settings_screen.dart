import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/sticker_card.dart';
import '../garden_home/notification_service.dart';

/// S13 — parent-facing settings on a themed guidebook card. Sound and the
/// daily reminder are the only two knobs a child/parent needs today; both
/// persist in the save blob and apply immediately.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameSaveProvider).valueOrNull;
    final settings = game?.settings;

    return Scaffold(
      backgroundColor: LaarishColors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(LaarishSpacing.lg),
            child: StickerCard(
              padding: const EdgeInsets.all(LaarishSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Settings', style: LaarishText.display28, textAlign: TextAlign.center),
                  const SizedBox(height: LaarishSpacing.sm),
                  Text(
                    'Parent gate protects this page',
                    style: LaarishText.body16.copyWith(color: LaarishColors.soil),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: LaarishSpacing.xl),
                  if (settings == null)
                    const Padding(
                      padding: EdgeInsets.all(LaarishSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _ToggleRow(
                      icon: Icons.volume_up_rounded,
                      label: 'Sound effects',
                      value: settings.soundOn,
                      onChanged: (v) {
                        AudioService.instance.setMuted(!v);
                        ref.read(gameSaveProvider.notifier).mutate((s) {
                          s.settings.soundOn = v;
                          return s;
                        });
                      },
                    ),
                    const SizedBox(height: LaarishSpacing.sm),
                    _ToggleRow(
                      icon: Icons.notifications_active_rounded,
                      label: 'Daily reminder',
                      value: settings.remindersOn,
                      onChanged: (v) {
                        GardenNotificationService.instance.setEnabled(v);
                        ref.read(gameSaveProvider.notifier).mutate((s) {
                          s.settings.remindersOn = v;
                          return s;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: LaarishSpacing.xl),
                  Text(
                    'Laarish • v1.0.0',
                    style: LaarishText.body16.copyWith(color: LaarishColors.soil.withValues(alpha: 0.6)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: LaarishSpacing.lg),
                  LaarishButton(
                    label: 'Back to Garden',
                    color: LaarishColors.soil,
                    onTap: () => context.go('/garden'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: LaarishColors.soil, size: 24),
        const SizedBox(width: LaarishSpacing.md),
        Expanded(child: Text(label, style: LaarishText.body16)),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: LaarishColors.leaf,
          activeThumbColor: Colors.white,
        ),
      ],
    );
  }
}
