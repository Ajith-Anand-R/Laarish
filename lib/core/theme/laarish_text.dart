import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'laarish_colors.dart';

/// Display = Baloo 2 (rounded/chunky, guidebook headers). Body = Nunito.
/// DESIGN_SYSTEM.md §2.
class LaarishText {
  LaarishText._();

  static TextStyle display34 = GoogleFonts.baloo2(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: LaarishColors.ink,
    height: 1.1,
  );

  static TextStyle display28 = GoogleFonts.baloo2(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: LaarishColors.ink,
    height: 1.15,
  );

  static TextStyle display22 = GoogleFonts.baloo2(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: LaarishColors.ink,
    height: 1.2,
  );

  static TextStyle body18 = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: LaarishColors.ink,
    height: 1.3,
  );

  static TextStyle body16 = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: LaarishColors.ink,
  );

  static TextStyle button = GoogleFonts.baloo2(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}
