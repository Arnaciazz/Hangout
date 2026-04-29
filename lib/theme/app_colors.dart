import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === Brand Colors ===
  static const Color primaryGreen = Color(0xFF58CC02);
  static const Color primaryGreenDark = Color(0xFF2B6C00);
  static const Color primaryGreenLight = Color(0xFF87FE45);
  static const Color primaryGreenDim = Color(0xFF6BE026);

  static const Color secondaryPurple = Color(0xFFCE82FF);
  static const Color secondaryPurpleDark = Color(0xFF843AB4);
  static const Color secondaryPurpleDeep = Color(0xFF6A1C9A);
  static const Color secondaryPurpleLight = Color(0xFFF4D9FF);

  static const Color tertiaryOrange = Color(0xFFFF9600);
  static const Color tertiaryOrangeDark = Color(0xFF8C5000);
  static const Color tertiaryOrangeLight = Color(0xFFFFDCBF);
  static const Color tertiaryOrangeContainer = Color(0xFFFF9C27);

  // === Neutral Colors ===
  static const Color background = Color(0xFFF9F9F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);
  static const Color surfaceDim = Color(0xFFDADADA);

  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF3F4A36);
  static const Color outline = Color(0xFF6F7B64);
  static const Color outlineVariant = Color(0xFFBECBB1);

  static const Color inverseSurface = Color(0xFF2F3131);
  static const Color inverseOnSurface = Color(0xFFF1F1F1);

  // === Semantic Colors ===
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);

  // === Sticker Effect Shadows ===
  static const Color stickerShadow = Color(0x1A58CC02);
  static const Color cardBorder = Color(0xFFE5E5E5);
  static const Color cardBorderDark = Color(0xFFD0D0D0);

  // === Gradient Helpers ===
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF58CC02), Color(0xFF6BE026)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCE82FF), Color(0xFFE4B5FF)],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9600), Color(0xFFFFB872)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC000000)],
  );
}
