import 'package:flutter/material.dart';

/// Hangout colour tokens — ported 1:1 from the Hangout Design System
/// (`tokens/colors.css`).
///
/// Warm, appetizing, social. Paprika red-orange leads; avocado green is the
/// fresh counterpoint; honey amber warms ratings and highlights. Neutrals are
/// warm-tinted sand — never cold grey.
///
/// Use the *semantic* aliases (`brand`, `surface`, `textMuted`, …) in UI code;
/// reach for a raw scale step only when no role fits.
///
/// Colour carries meaning here, so keep it honest:
/// - **Paprika** — the primary action, the current selection, live state.
/// - **Avocado** — confirmation and positive outcomes only ("You're in").
/// - **Honey** — ratings.
/// Everything else is warm sand.
class AppColors {
  AppColors._();

  // ─── Brand · Paprika (primary) ─────────────────────────────────────────────
  static const Color paprika50 = Color(0xFFFFF1EE);
  static const Color paprika100 = Color(0xFFFFDDD5);
  static const Color paprika200 = Color(0xFFFFB9A9);
  static const Color paprika300 = Color(0xFFFB8E78);
  static const Color paprika400 = Color(0xFFF26647);
  static const Color paprika500 = Color(0xFFE8462B); // core brand
  static const Color paprika600 = Color(0xFFC8341C);
  static const Color paprika700 = Color(0xFFA02714);
  static const Color paprika800 = Color(0xFF711A0D);

  // ─── Brand · Avocado (fresh secondary) ─────────────────────────────────────
  static const Color avocado50 = Color(0xFFF3F8E9);
  static const Color avocado100 = Color(0xFFE1EFC5);
  static const Color avocado200 = Color(0xFFC6E092);
  static const Color avocado300 = Color(0xFFA8CE5C);
  static const Color avocado400 = Color(0xFF8CBB38);
  static const Color avocado500 = Color(0xFF6FA82C); // core green
  static const Color avocado600 = Color(0xFF578522);
  static const Color avocado700 = Color(0xFF41631A);

  // ─── Brand · Honey (ratings / highlights) ──────────────────────────────────
  static const Color honey100 = Color(0xFFFFF0CC);
  static const Color honey300 = Color(0xFFFFD466);
  static const Color honey500 = Color(0xFFFFB020);
  static const Color honey600 = Color(0xFFE5920A);

  // ─── Warm neutrals (cream → ink) ───────────────────────────────────────────
  static const Color sand0 = Color(0xFFFFFFFF);
  static const Color sand50 = Color(0xFFFFF9F5);
  static const Color sand100 = Color(0xFFFBF1E9);
  static const Color sand200 = Color(0xFFF1E4D9);
  static const Color sand300 = Color(0xFFE2D2C4);
  static const Color sand400 = Color(0xFFC4AF9F);
  static const Color sand500 = Color(0xFF9A8879);
  static const Color sand600 = Color(0xFF726357);
  static const Color sand700 = Color(0xFF4E4239);
  static const Color sand800 = Color(0xFF332A24);
  static const Color sand900 = Color(0xFF241A16); // warm ink

  // ─── Semantic hues ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2FA45B);
  static const Color warning = Color(0xFFE5920A);
  static const Color danger = Color(0xFFDB3A2B);
  static const Color info = Color(0xFF2F7DBF);

  // ─── Semantic aliases — use these in components ────────────────────────────
  static const Color brand = paprika500;
  static const Color brandHover = paprika600;
  static const Color brandPress = paprika700;
  static const Color brandSoft = paprika100;
  static const Color brandTint = paprika50;
  static const Color accentFresh = avocado500;
  static const Color accentFreshSoft = avocado100;
  static const Color accentFreshTint = avocado50;
  static const Color accentWarm = honey500;
  static const Color rating = honey500;

  static const Color bg = sand50;
  static const Color surface = sand0;
  static const Color surfaceSunken = sand100;
  static const Color surfaceInverse = sand900;

  static const Color textStrong = sand900;
  static const Color textBody = sand800;
  static const Color textMuted = sand600;
  static const Color textFaint = sand500;
  static const Color textOnBrand = Color(0xFFFFFFFF);
  static const Color textOnDark = sand50;

  static const Color border = sand200;
  static const Color borderStrong = sand300;
  static const Color focusRing = paprika400;

  // ─── Imagery ───────────────────────────────────────────────────────────────

  /// Bottom-up protection gradient for text laid over photography. The only
  /// gradient in the system: the design system requires it behind any label
  /// that sits on a photo, and uses no decorative gradients anywhere else.
  static const LinearGradient photoScrim = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xE6241A16), Color(0x66241A16), Color(0x00241A16)],
    stops: [0.0, 0.45, 1.0],
  );

  static const Color dangerTint = Color(0xFFFFE9E6);
}
