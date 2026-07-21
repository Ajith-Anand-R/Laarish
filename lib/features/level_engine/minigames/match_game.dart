import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../content/models/level_content.dart';
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

  void _tapRight(int i) {
    if (_selectedLeft == null) return;
    final leftWord = _left[_selectedLeft!];
    final rightWord = _right[i];
    final isMatch = _pairs.any((p) => p[0] == leftWord && p[1] == rightWord);
    if (isMatch) {
      HapticFeedback.lightImpact();
      final matchedIndex = _pairs.indexWhere((p) => p[0] == leftWord);
      setState(() {
        _matched.add(matchedIndex);
        _selectedLeft = null;
      });
      if (_matched.length == _pairs.length) widget.onComplete();
    } else {
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
            Column(children: [for (var i = 0; i < _left.length; i++) _chip(_left[i], _matched.contains(i), _selectedLeft == i, () => _tapLeft(i))]),
            Column(children: [for (var i = 0; i < _right.length; i++) _chip(_right[i], _matched.any((m) => _pairs[m][1] == _right[i]), false, () => _tapRight(i))]),
          ],
        ),
      ],
    );
  }

  Widget _chip(String text, bool done, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: JuicyTap(
        enabled: !done,
        onTap: onTap,
        child: Container(
          width: 130,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: done
                ? LaarishColors.leaf.withValues(alpha: 0.3)
                : (selected ? widget.color.withValues(alpha: 0.3) : Colors.white),
            border: Border.all(color: widget.color, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: LaarishText.body16, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
