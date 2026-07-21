import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../content/models/level_content.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/fx/fx.dart';
import '../../../core/theme/laarish_colors.dart';
import '../../../core/theme/laarish_text.dart';
import 'minigame_common.dart';

/// game: "match" — pair kit-tool characters with their job (CANON.md §1
/// "Kit tool characters"). Reads an optional `pairs: [[left,right],...]`
/// from the content JSON; falls back to the canon 4 tools when WS7 hasn't
/// shipped a custom list yet.
class MatchGame extends StatefulWidget {
  const MatchGame({super.key, required this.step, required this.color, required this.onComplete});
  final LevelStep step;
  final Color color;
  final VoidCallback onComplete;

  static const _defaultPairs = [
    ['Corky', 'Coir cup'],
    ['Diggy', 'Ruler & mixer'],
    ['Misty', 'Spray bottle'],
    ['Cuppy', '~100 ml cup'],
  ];

  @override
  State<MatchGame> createState() => _MatchGameState();
}

class _MatchGameState extends State<MatchGame> {
  late final List<List<String>> _pairs;
  late final List<String> _left;
  late final List<String> _right;
  int? _selectedLeft;
  final Set<int> _matched = {};

  @override
  void initState() {
    super.initState();
    final raw = widget.step.raw['pairs'] as List?;
    _pairs = raw != null
        ? raw.map((p) => (p as List).cast<String>()).toList()
        : MatchGame._defaultPairs;
    _left = _pairs.map((p) => p[0]).toList();
    _right = _pairs.map((p) => p[1]).toList()..shuffle();
  }

  void _tapLeft(int i) {
    if (_matched.contains(i)) return;
    setState(() => _selectedLeft = i);
  }

  /// Anchors for the burst fired on the right-hand chip that just matched.
  final _rightKeys = <int, GlobalKey>{};

  GlobalKey _rightKey(int i) => _rightKeys.putIfAbsent(i, GlobalKey.new);

  void _tapRight(int i) {
    if (_selectedLeft == null) return;
    final leftWord = _left[_selectedLeft!];
    final rightWord = _right[i];
    final isMatch = _pairs.any((p) => p[0] == leftWord && p[1] == rightWord);
    if (isMatch) {
      HapticFeedback.mediumImpact();
      AudioService.instance.play(Sfx.sparkle);
      FxBurst.atWidget(
        _rightKey(i),
        color: LaarishColors.leaf,
        style: BurstStyle.shock,
      );
      final matchedIndex = _pairs.indexWhere((p) => p[0] == leftWord);
      setState(() {
        _matched.add(matchedIndex);
        _selectedLeft = null;
      });
      if (_matched.length == _pairs.length) {
        // Clearing the board is the payoff — the whole world reacts.
        ShakeScope.go(context, intensity: 12, haptic: HapticImpact.heavy);
        FxBurst.atWidget(
          _rightKey(i),
          color: LaarishColors.sunflower,
          style: BurstStyle.celebrate,
          intensity: 1.3,
        );
        widget.onComplete();
      } else {
        ShakeScope.go(context, intensity: 5, haptic: HapticImpact.none);
      }
    } else {
      // Wrong pair: a gentle bump and the selection clears. No penalty, no
      // lock-out (AGENT.md "no failure states").
      HapticFeedback.lightImpact();
      setState(() => _selectedLeft = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinigamePrompt(text: widget.step.prompt ?? 'Match each tool to its job!'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ChainReveal(
              axis: Axis.vertical,
              gap: const Duration(milliseconds: 70),
              slide: 14,
              children: [
                for (var i = 0; i < _left.length; i++)
                  _chip(_left[i], _matched.contains(i), _selectedLeft == i,
                      () => _tapLeft(i)),
              ],
            ),
            ChainReveal(
              axis: Axis.vertical,
              gap: const Duration(milliseconds: 70),
              slide: 14,
              children: [
                for (var i = 0; i < _right.length; i++)
                  KeyedSubtree(
                    key: _rightKey(i),
                    child: _chip(
                      _right[i],
                      _matched.any((m) => _pairs[m][1] == _right[i]),
                      false,
                      () => _tapRight(i),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String text, bool done, bool selected, VoidCallback onTap) {
    Widget chip = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: done
              ? [
                  Color.lerp(LaarishColors.leaf, Colors.white, 0.5)!,
                  LaarishColors.leaf,
                ]
              : selected
                  ? [
                      Color.lerp(widget.color, Colors.white, 0.55)!,
                      widget.color,
                    ]
                  : [Colors.white, LaarishColors.paperDeep],
        ),
        border: Border.all(
          color: done ? LaarishColors.leafDeep : widget.color,
          width: selected || done ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: DepthShadow.shadows(
          done ? LaarishColors.leafDeep : LaarishColors.soil,
          selected ? 1.6 : 0.8,
        ),
      ),
      child: Text(
        text,
        style: LaarishText.body16.copyWith(
          color: done || selected ? Colors.white : LaarishColors.ink,
          fontWeight: done || selected ? FontWeight.w800 : FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );

    // A picked-but-unmatched chip hovers, waiting for its partner.
    if (selected) {
      chip = PulseGlow(
        color: widget.color,
        radius: 16,
        intensity: 0.55,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(14),
        child: chip,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: done ? 0.85 : 1,
        child: JuicyTap(
          enabled: !done,
          onTap: onTap,
          sparkColor: widget.color,
          borderRadius: BorderRadius.circular(14),
          child: chip,
        ),
      ),
    );
  }
}
