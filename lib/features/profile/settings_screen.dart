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
import '../../data/local/entities.dart';
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
                  Text('Me', style: LaarishText.display28, textAlign: TextAlign.center),
                  const SizedBox(height: LaarishSpacing.lg),
                  if (game != null) ...[
                    _AccountCard(game: game),
                    const SizedBox(height: LaarishSpacing.xl),
                  ],
                  Text('Settings', style: LaarishText.display22, textAlign: TextAlign.center),
                  const SizedBox(height: LaarishSpacing.sm),
                  Text(
                    'Parent gate protects this page',
                    style: LaarishText.body16.copyWith(color: LaarishColors.soil),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: LaarishSpacing.lg),
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

/// Account details for the child's profile — buddy avatar, name, chosen guide,
/// join date and their point/coin wallet.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.game});
  final GameSave game;

  @override
  Widget build(BuildContext context) {
    final p = game.profile;
    final joined = '${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year}';
    final buddyName = p.buddy == 'ayra' ? 'Ayra' : 'Rishi';
    return Container(
      padding: const EdgeInsets.all(LaarishSpacing.lg),
      decoration: BoxDecoration(
        color: LaarishColors.paperDeep,
        borderRadius: BorderRadius.circular(LaarishSpacing.cardRadius),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/${p.buddy}_character.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.person_rounded, size: 40, color: LaarishColors.soil),
                  ),
                ),
              ),
              const SizedBox(width: LaarishSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name.isEmpty ? 'Young Agriculturist' : p.name,
                        style: LaarishText.display22),
                    Text('Buddy: $buddyName', style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
                    Text('Joined $joined',
                        style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LaarishSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _WalletChip(icon: Icons.wb_sunny_rounded, value: game.wallet.sunPoints, color: LaarishColors.sunflowerDeep),
              _WalletChip(icon: Icons.eco_rounded, value: game.wallet.seedCoins, color: LaarishColors.leaf),
              _WalletChip(icon: Icons.local_fire_department_rounded, value: game.streak.current, color: LaarishColors.tomato),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({required this.icon, required this.value, required this.color});
  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: LaarishSpacing.xs),
        Text('$value', style: LaarishText.body18.copyWith(fontWeight: FontWeight.w800)),
      ],
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
