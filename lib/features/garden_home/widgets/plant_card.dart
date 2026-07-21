import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/motion/laarish_motion.dart';
import '../../../core/theme/laarish_colors.dart';
import '../../../core/theme/laarish_spacing.dart';
import '../../../core/theme/laarish_text.dart';
import '../../../core/widgets/mascot_view.dart';
import '../../../core/widgets/ribbon_banner.dart';
import '../../../core/widgets/sticker_card.dart';
import '../../../data/local/entities.dart';
import '../../../domain/mission_generator.dart';
import 'soil_mound.dart';

const Map<String, String> _plantTitles = {
  'tommy': 'Tommy the Climber',
  'okki': 'Okki the Speedster',
  'chilly': 'Chilly the Slow Burn',
  'methi': 'Methi the Quick Greens',
};

/// Mascot-voice greeting per stage — short, ≤8 words (DESIGN_SYSTEM.md §2).
String _greeting(String plantId, PlantStage stage) {
  final name = _plantTitles[plantId]?.split(' ').first ?? plantId;
  switch (stage) {
    case PlantStage.locked:
      return '$name is waiting to begin!';
    case PlantStage.nursery:
      return 'Hi! $name needs you today.';
    case PlantStage.thinned:
      return '$name is growing strong!';
    case PlantStage.graduated:
      return '$name is ready for the big move!';
    case PlantStage.growBag:
      return '$name is settling into the grow bag!';
    case PlantStage.flowering:
      return '$name is flowering — exciting!';
    case PlantStage.harvested:
      return '$name has treats for you!';
    case PlantStage.round2:
      return '$name is back for round two!';
  }
}

class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.plant,
    required this.missions,
    required this.completedIds,
    required this.onToggle,
    required this.today,
  });

  final PlantProgress plant;
  final List<Mission> missions;
  final Set<String> completedIds;
  final void Function(String missionId) onToggle;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final biome = LaarishColors.biome[plant.plantId] ?? LaarishColors.leafDeep;
    final window = sproutWindowDays[plant.plantId];
    final showSoilMound = plant.stage == PlantStage.nursery &&
        plant.realDates.sproutedAt == null &&
        plant.realDates.plantedAt != null &&
        window != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: LaarishSpacing.lg),
      child: StickerCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PlantArt(plantId: plant.plantId, biome: biome),
                const SizedBox(width: LaarishSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RibbonBanner(text: _plantTitles[plant.plantId] ?? plant.plantId, color: biome),
                      const SizedBox(height: LaarishSpacing.sm),
                      Text(_greeting(plant.plantId, plant.stage), style: LaarishText.body18),
                    ],
                  ),
                ),
              ],
            ),
            if (showSoilMound) ...[
              const SizedBox(height: LaarishSpacing.md),
              Center(
                child: SoilMound(
                  daysElapsed: daysSince(plant.realDates.plantedAt, today) ?? 0,
                  totalDays: window.$2,
                  plantId: plant.plantId,
                ),
              ),
            ],
            if (missions.isNotEmpty) ...[
              const SizedBox(height: LaarishSpacing.md),
              for (final mission in missions)
                _MissionTile(
                  mission: mission,
                  done: completedIds.contains(mission.id),
                  onTap: () => onToggle(mission.id),
                ),
            ],
            _PhotoDiary(photos: plant.photos),
          ],
        ),
      ),
    );
  }
}

class _PlantArt extends StatelessWidget {
  const _PlantArt({required this.plantId, required this.biome});
  final String plantId;
  final Color biome;

  @override
  Widget build(BuildContext context) {
    // Live mascot greeting the child (GAMIFICATION.md §3 "plants greet you").
    return SizedBox(
      width: 84,
      height: 84,
      child: MascotView.plant(plantId, size: 84, energy: mascotEnergy(plantId)),
    );
  }
}

class _MissionTile extends StatefulWidget {
  const _MissionTile({required this.mission, required this.done, required this.onTap});
  final Mission mission;
  final bool done;
  final VoidCallback onTap;

  @override
  State<_MissionTile> createState() => _MissionTileState();
}

class _MissionTileState extends State<_MissionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LaarishSpacing.sm),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          AudioService.instance.play(widget.done ? Sfx.tap : Sfx.pop);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? LaarishMotion.tapSquash : 1.0,
          duration: LaarishMotion.tapDown,
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.all(LaarishSpacing.sm),
            constraints: const BoxConstraints(minHeight: LaarishSpacing.minTapTarget),
            decoration: BoxDecoration(
              color: widget.done ? LaarishColors.leaf.withValues(alpha: 0.18) : LaarishColors.paperDeep,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                AnimatedScale(
                  scale: widget.done ? 1.0 : 0.001,
                  duration: LaarishMotion.tapUp,
                  curve: LaarishMotion.enter,
                  child: const Icon(Icons.check_circle_rounded, color: LaarishColors.leafDeep),
                ),
                if (!widget.done)
                  const Icon(Icons.circle_outlined, color: LaarishColors.soil),
                const SizedBox(width: LaarishSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mission.title,
                        style: LaarishText.body18.copyWith(
                          decoration: widget.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text(widget.mission.detail, style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoDiary extends StatelessWidget {
  const _PhotoDiary({required this.photos});
  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: LaarishSpacing.sm),
      child: photos.isEmpty
          ? Text('No photos yet — snap one during a real task!', style: LaarishText.body16.copyWith(color: LaarishColors.soil))
          : SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: LaarishSpacing.sm),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(photos[i]), width: 64, height: 64, fit: BoxFit.cover),
                ),
              ),
            ),
    );
  }
}
