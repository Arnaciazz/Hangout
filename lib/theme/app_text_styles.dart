import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Hangout typography.
///
/// Two faces, each with one job:
/// - **Bricolage Grotesque** for headlines, place names and numbers. A warm,
///   slightly irregular grotesque — it has the appetite and energy of the
///   brand without shouting.
/// - **Figtree** for everything you read or tap: body, labels, buttons, meta.
///
/// The scale is deliberately tight (~1.2 between steps). This is an app people
/// use mid-plan on a phone, not a landing page; hierarchy comes from weight
/// and one clear title per screen, not from giant type.
///
/// There is intentionally no all-caps "overline" style. Labels above headings
/// were removed app-wide; a heading carries its own weight.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _display({
    required double size,
    required FontWeight weight,
    required double height,
    double tracking = -0.02,
    Color color = AppColors.textStrong,
  }) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: size * tracking,
        color: color,
      );

  static TextStyle _text({
    required double size,
    required FontWeight weight,
    required double height,
    double tracking = 0,
    Color color = AppColors.textBody,
  }) =>
      GoogleFonts.figtree(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: size * tracking,
        color: color,
      );

  // ─── Display face ──────────────────────────────────────────────────────────

  /// Screen title — one per screen.
  static TextStyle get h1 =>
      _display(size: 32, weight: FontWeight.w700, height: 1.1);

  /// Sheet and hero titles.
  static TextStyle get h2 =>
      _display(size: 26, weight: FontWeight.w700, height: 1.15);

  /// Section titles.
  static TextStyle get h3 =>
      _display(size: 21, weight: FontWeight.w600, height: 1.2, tracking: -0.01);

  /// Card titles and place names.
  static TextStyle get title =>
      _display(size: 18, weight: FontWeight.w600, height: 1.25, tracking: -0.01);

  /// Numbers that are the point: codes, vote shares, counts.
  static TextStyle statNumber(double size) =>
      _display(size: size, weight: FontWeight.w700, height: 1.05);

  // ─── Text face ─────────────────────────────────────────────────────────────

  static TextStyle get body =>
      _text(size: 16, weight: FontWeight.w400, height: 1.5);

  static TextStyle get bodyStrong => _text(
      size: 16,
      weight: FontWeight.w600,
      height: 1.4,
      color: AppColors.textStrong);

  static TextStyle get small => _text(
      size: 14, weight: FontWeight.w400, height: 1.45, color: AppColors.textMuted);

  static TextStyle get smallStrong =>
      _text(size: 14, weight: FontWeight.w600, height: 1.35);

  static TextStyle get caption => _text(
      size: 12.5,
      weight: FontWeight.w500,
      height: 1.35,
      color: AppColors.textMuted);

  static TextStyle get captionStrong =>
      _text(size: 12.5, weight: FontWeight.w600, height: 1.3);

  /// Button label. Size is set per button size.
  static TextStyle get button => _text(
        size: 15.5,
        weight: FontWeight.w600,
        height: 1.0,
        color: AppColors.textOnBrand,
      );
}
