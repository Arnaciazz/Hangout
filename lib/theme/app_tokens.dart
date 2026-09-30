import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Spacing scale — 4px base. From the design system's `tokens/spacing.css`.
class AppSpacing {
  AppSpacing._();

  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;

  /// Standard horizontal page gutter.
  static const double gutter = 20;
}

/// Corner radii — soft, friendly, generous.
///
/// Cards get [xl], inputs and stat boxes [md], sheets [xxl]; buttons and chips
/// are full [pill]s.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 36;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlAll = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// Top-only rounding for bottom sheets.
  static const BorderRadius sheetTop =
      BorderRadius.vertical(top: Radius.circular(xxl));
}

/// Warm-tinted, soft, diffuse elevation. Never hard black drop shadows.
class AppShadows {
  AppShadows._();

  static const Color _warm = Color(0xFF342A24);

  static List<BoxShadow> get sm => [
        BoxShadow(color: _warm.withValues(alpha: 0.06), blurRadius: 2, offset: const Offset(0, 1)),
        BoxShadow(color: _warm.withValues(alpha: 0.08), blurRadius: 3, offset: const Offset(0, 1)),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(color: _warm.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        BoxShadow(color: _warm.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2)),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(color: _warm.withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, 12)),
        BoxShadow(color: _warm.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
      ];

  static List<BoxShadow> get xl => [
        BoxShadow(color: _warm.withValues(alpha: 0.18), blurRadius: 48, offset: const Offset(0, 24)),
      ];

  /// Coloured lift carried by the primary action only — the one paprika
  /// button on a screen and the raised centre tab. Nothing else glows.
  static List<BoxShadow> get brand => [
        BoxShadow(
          color: AppColors.brand.withValues(alpha: 0.32),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  /// Lift for the confirm ("You're in") button.
  static List<BoxShadow> get fresh => [
        BoxShadow(
          color: AppColors.accentFresh.withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  /// Upward shadow for the bottom nav bar.
  static List<BoxShadow> get navBar => [
        BoxShadow(
          color: _warm.withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, -6),
        ),
      ];
}

/// Motion tokens. Hangout is quick and springy: presses *bounce*, they don't
/// just darken. Nothing linear, nothing long.
///
/// Motion reports state — a press, a selection, a card leaving the deck. It is
/// never an entrance sequence: screens load straight into the task.
class AppMotion {
  AppMotion._();

  /// `cubic-bezier(.22,.61,.36,1)` — the default for transitions.
  static const Curve easeOut = Cubic(0.22, 0.61, 0.36, 1);

  /// `cubic-bezier(.34,1.56,.64,1)` — overshoot, for taps and things that pop.
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);

  /// Symmetric ease for state cross-fades.
  static const Curve easeInOut = Cubic(0.45, 0, 0.25, 1);

  static const Duration fast = Duration(milliseconds: 130);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 360);

  /// Route push/pop.
  static const Duration page = Duration(milliseconds: 300);
}
