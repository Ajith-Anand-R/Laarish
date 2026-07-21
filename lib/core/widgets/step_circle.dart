import 'package:flutter/material.dart';
import '../theme/laarish_colors.dart';
import '../theme/laarish_text.dart';

/// Numbered step circle — guidebook ①②③ style.
class StepCircle extends StatelessWidget {
  const StepCircle({super.key, required this.number, this.color = LaarishColors.tomato});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        '$number',
        style: LaarishText.button.copyWith(fontSize: 15),
      ),
    );
  }
}
