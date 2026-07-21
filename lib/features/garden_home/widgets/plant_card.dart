import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/fx/fx.dart';
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
        elevation: 1.4,
        // A plant with work left glows quietly — the card itself asks for
        // attention instead of relying on the child reading every row.
        glow: missions.any((m) => !completedIds.contains(m.id)) ? biome : null,
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
              // Today's jobs cascade in rather than appearing as a wall.
              ChainReveal(
                axis: Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                gap: const Duration(milliseconds: 70),
                slide: 12,
                children: [
                  for (final mission in missions)
                    _MissionTile(
                      mission: mission,
                      done: completedIds.contains(mission.id),
                      color: biome,
                      onTap: () => onToggle(mission.id),
                    ),
                ],
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

/// One daily job. Ticking it is the smallest reward loop in the app, so it
/// gets the full treatment: magnetic press, a burst from the checkbox, a light
/// world-knock, and the row itself lifting into a lit "done" state.
class _MissionTile extends StatefulWidget {
  const _MissionTile({
    required this.mission,
    required this.done,
    required this.onTap,
    required this.color,
  });

  final Mission mission;
  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_MissionTile> createState() => _MissionTileState();
}

class _MissionTileState extends State<_MissionTile> {
  final _checkKey = GlobalKey();

  void _tap() {
    final completing = !widget.done;
    AudioService.instance.play(completing ? Sfx.pop : Sfx.tap);
    if (completing) {
      ShakeScope.go(context, intensity: 5, haptic: HapticImpact.medium);
      FxBurst.atWidget(
        _checkKey,
        color: LaarishColors.leaf,
        style: BurstStyle.pop,
        intensity: 0.8,
      );
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.done;
    return Padding(
      padding: const EdgeInsets.only(bottom: LaarishSpacing.sm),
      child: MagneticTap(
        onTap: _tap,
        sfx: null, // played in _tap so it can differ by direction
        magnetStrength: 4,
        borderRadius: BorderRadius.circular(16),
        rippleColor: widget.color.withValues(alpha: 0.45),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(LaarishSpacing.sm),
          constraints: const BoxConstraints(minHeight: LaarishSpacing.minTapTarget),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: done
                  ? [
                      LaarishColors.leaf.withValues(alpha: 0.30),
                      LaarishColors.leaf.withValues(alpha: 0.12),
                    ]
                  : [Colors.white, LaarishColors.paperDeep],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done
                  ? LaarishColors.leafDeep.withValues(alpha: 0.45)
                  : LaarishColors.soil.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: DepthShadow.shadows(
              done ? LaarishColors.leafDeep : LaarishColors.soil,
              done ? 0.8 : 0.45,
            ),
          ),
          child: Row(
            children: [
              // Checkbox swaps with a spring pop, and the pop is what the
              // particle burst is anchored to.
              SizedBox(
                key: _checkKey,
                width: 26,
                height: 26,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedScale(
                      scale: done ? 0.001 : 1.0,
                      duration: LaarishMotion.tapUp,
                      curve: Curves.easeIn,
                      child: const Icon(Icons.circle_outlined,
                          color: LaarishColors.soil, size: 24),
                    ),
                    AnimatedScale(
                      scale: done ? 1.0 : 0.001,
                      duration: const Duration(milliseconds: 380),
                      curve: LaarishMotion.overshoot,
                      child: const Icon(Icons.check_circle_rounded,
                          color: LaarishColors.leafDeep, size: 26),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LaarishSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 280),
                      style: LaarishText.body18.copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done
                            ? LaarishColors.leafDeep
                            : LaarishColors.ink,
                      ),
                      child: Text(widget.mission.title),
                    ),
                    Text(
                      widget.mission.detail,
                      style: LaarishText.body16
                          .copyWith(color: LaarishColors.soil),
                    ),
                  ],
                ),
              ),
            ],
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
                // Each polaroid is a little 3D object that catches the light
                // as the phone moves.
                itemBuilder: (_, i) => Tilt3D(
                  maxTilt: 0.28,
                  deviceTiltAmount: 0.7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: DepthShadow.shadows(LaarishColors.soil, 0.7),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(photos[i]),
                          width: 64, height: 64, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
