import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../app/providers.dart';
import '../../core/ai/mentor_service.dart';
import '../../core/media/media_service.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/mascot_view.dart';
import '../../core/widgets/speech_bubble.dart';
import '../../core/widgets/sticker_card.dart';

/// `video` step — a short recap video the child watches to finish the level.
/// Looks for `assets/video/<plant>_l<level>.mp4`; if that isn't shipped yet it
/// falls back to a themed recap card (never blocks the child). Continue
/// unlocks once the video has played through (or immediately, on fallback).
class LevelVideoStep extends StatefulWidget {
  const LevelVideoStep({
    super.key,
    required this.plantId,
    required this.level,
    required this.color,
    required this.title,
    required this.onDone,
  });

  final String plantId;
  final int level;
  final Color color;
  final String title;
  final VoidCallback onDone;

  @override
  State<LevelVideoStep> createState() => _LevelVideoStepState();
}

class _LevelVideoStepState extends State<LevelVideoStep> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _watched = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = VideoPlayerController.asset('assets/video/${widget.plantId}_l${widget.level}.mp4');
    try {
      await c.initialize();
      c.addListener(_tick);
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() => _controller = c);
      c.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true); // no per-level video yet
    }
  }

  void _tick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (!_watched && c.value.duration > Duration.zero && c.value.position >= c.value.duration) {
      setState(() => _watched = true);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_tick);
    _controller?.dispose();
    super.dispose();
  }

  bool get _canContinue => _failed || _watched;

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Level recap', style: LaarishText.display22, textAlign: TextAlign.center),
        const SizedBox(height: LaarishSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: c != null && c.value.isInitialized
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(c),
                      GestureDetector(
                        onTap: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
                        child: AnimatedOpacity(
                          opacity: c.value.isPlaying ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white),
                        ),
                      ),
                    ],
                  )
                : _RecapFallback(plantId: widget.plantId, color: widget.color, title: widget.title),
          ),
        ),
        const SizedBox(height: LaarishSpacing.lg),
        Opacity(
          opacity: _canContinue ? 1 : 0.4,
          child: IgnorePointer(
            ignoring: !_canContinue,
            child: LaarishButton(
              label: _canContinue ? 'I watched it!' : 'Watching…',
              color: widget.color,
              onTap: widget.onDone,
            ),
          ),
        ),
      ],
    );
  }
}

/// Themed recap shown when no per-level video is on disk yet — the mascot
/// celebrates the finished level so "watch to finish" still has a payoff.
class _RecapFallback extends StatelessWidget {
  const _RecapFallback({required this.plantId, required this.color, required this.title});
  final String plantId;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(colors: [color.withValues(alpha: 0.25), LaarishColors.paperDeep]),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MascotView.plant(plantId, size: 96, energy: mascotEnergy(plantId)),
            const SizedBox(height: 8),
            Text('You did it!', style: LaarishText.display22),
          ],
        ),
      ),
    );
  }
}

/// `capture` step — after the recap, the child may snap a progress photo of
/// their real plant. The AI Mentor then gives warm, specific feedback. The
/// photo is saved to the plant's diary; skipping is always allowed.
class ProgressCaptureStep extends ConsumerStatefulWidget {
  const ProgressCaptureStep({
    super.key,
    required this.plantId,
    required this.level,
    required this.color,
    required this.prompt,
    required this.onDone,
  });

  final String plantId;
  final int level;
  final Color color;
  final String prompt;
  final VoidCallback onDone;

  @override
  ConsumerState<ProgressCaptureStep> createState() => _ProgressCaptureStepState();
}

enum _Phase { choosing, thinking, feedback }

class _ProgressCaptureStepState extends ConsumerState<ProgressCaptureStep> {
  _Phase _phase = _Phase.choosing;
  String? _photoPath;
  MentorFeedback? _feedback;

  Future<void> _pick(ImageSource source) async {
    setState(() => _phase = _Phase.thinking);
    final path = await MediaService.instance.capture(
      source: source,
      plantId: widget.plantId,
      level: widget.level,
    );
    if (path == null) {
      // Cancelled / permission denied — back to the choices, no fake feedback.
      if (mounted) setState(() => _phase = _Phase.choosing);
      return;
    }
    // Save to the plant's photo diary, then ask the mentor.
    await ref.read(gameSaveProvider.notifier).mutate((save) {
      save.plants[widget.plantId]?.photos.add(path);
      return save;
    });
    await _askMentor(path);
  }

  Future<void> _skip() async {
    setState(() => _phase = _Phase.thinking);
    await _askMentor(null);
  }

  Future<void> _askMentor(String? path) async {
    final mentor = ref.read(mentorServiceProvider);
    final fb = await mentor.feedbackForProgress(
      plantId: widget.plantId,
      level: widget.level,
      hasPhoto: path != null,
    );
    if (!mounted) return;
    setState(() {
      _photoPath = path;
      _feedback = fb;
      _phase = _Phase.feedback;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.choosing:
        return _buildChoosing();
      case _Phase.thinking:
        return _buildThinking();
      case _Phase.feedback:
        return _buildFeedback();
    }
  }

  Widget _buildChoosing() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MascotView.plant(widget.plantId, size: 120, glow: true, energy: mascotEnergy(widget.plantId)),
        const SizedBox(height: 12),
        Text(
          widget.prompt.isEmpty ? 'Show me your plant!' : widget.prompt,
          style: LaarishText.body18,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            LaarishButton(label: 'Take a photo', color: widget.color, icon: Icons.camera_alt_rounded, onTap: () => _pick(ImageSource.camera)),
            LaarishButton(label: 'Choose', color: LaarishColors.leafDeep, icon: Icons.photo_library_rounded, onTap: () => _pick(ImageSource.gallery)),
          ],
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _skip,
          child: Text('Skip for now', style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
        ),
      ],
    );
  }

  Widget _buildThinking() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MascotView.plant(widget.plantId, size: 110, energy: mascotEnergy(widget.plantId)),
        const SizedBox(height: 16),
        const CircularProgressIndicator(color: LaarishColors.leaf),
        const SizedBox(height: 16),
        Text('Mentor is looking…', style: LaarishText.body18),
      ],
    );
  }

  Widget _buildFeedback() {
    final fb = _feedback!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_photoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(File(_photoPath!), height: 160, fit: BoxFit.cover),
          ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 400.ms),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MascotView.plant(widget.plantId, size: 72, energy: mascotEnergy(widget.plantId)),
            const SizedBox(width: 8),
            Expanded(child: SpeechBubble(text: fb.headline)),
          ],
        ),
        const SizedBox(height: 12),
        StickerCard(
          color: LaarishColors.paperDeep,
          padding: const EdgeInsets.all(LaarishSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(fb.body, style: LaarishText.body16, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tips_and_updates_rounded, color: LaarishColors.sunflowerDeep, size: 18),
                  const SizedBox(width: 6),
                  Flexible(child: Text(fb.tip, style: LaarishText.body16.copyWith(color: LaarishColors.leafDeep))),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
        const SizedBox(height: 16),
        LaarishButton(label: 'Finish level', color: widget.color, onTap: widget.onDone),
      ],
    );
  }
}
