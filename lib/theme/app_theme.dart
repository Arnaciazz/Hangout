import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    return base.copyWith(
      // Screens render over the ambient [HangoutBackground], so scaffolds stay
      // transparent and the warm wash shows through.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,

      colorScheme: const ColorScheme.light(
        primary: AppColors.brand,
        onPrimary: AppColors.textOnBrand,
        primaryContainer: AppColors.brandSoft,
        onPrimaryContainer: AppColors.paprika700,
        secondary: AppColors.accentFresh,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.accentFreshSoft,
        onSecondaryContainer: AppColors.avocado700,
        tertiary: AppColors.accentWarm,
        onTertiary: AppColors.textStrong,
        tertiaryContainer: AppColors.honey100,
        onTertiaryContainer: AppColors.honey600,
        surface: AppColors.surface,
        onSurface: AppColors.textStrong,
        surfaceContainerLowest: AppColors.sand0,
        surfaceContainerLow: AppColors.sand50,
        surfaceContainer: AppColors.sand100,
        surfaceContainerHigh: AppColors.sand200,
        surfaceContainerHighest: AppColors.sand300,
        onSurfaceVariant: AppColors.textMuted,
        outline: AppColors.borderStrong,
        outlineVariant: AppColors.border,
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: AppColors.dangerTint,
        inverseSurface: AppColors.surfaceInverse,
        onInverseSurface: AppColors.textOnDark,
      ),

      // Material's roles mapped onto the Hangout scale, so stock widgets
      // (dialogs, list tiles, snackbars) pick up the brand faces too.
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h1,
        displaySmall: AppTextStyles.h2,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        headlineSmall: AppTextStyles.h3,
        titleLarge: AppTextStyles.h3,
        titleMedium: AppTextStyles.title,
        titleSmall: AppTextStyles.bodyStrong,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.small,
        labelLarge: AppTextStyles.smallStrong,
        labelMedium: AppTextStyles.captionStrong,
        labelSmall: AppTextStyles.caption,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textStrong, size: 22),
        titleTextStyle: AppTextStyles.title,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.textOnBrand,
          disabledBackgroundColor: AppColors.brand.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
          textStyle: AppTextStyles.button,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.textOnBrand,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
          textStyle: AppTextStyles.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textStrong,
          backgroundColor: AppColors.surface,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
          side: const BorderSide(color: AppColors.borderStrong, width: 1),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.textStrong),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
          textStyle: AppTextStyles.smallStrong,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.brandTint,
        selectedColor: AppColors.brand,
        checkmarkColor: Colors.white,
        side: const BorderSide(color: AppColors.paprika100),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        labelStyle: AppTextStyles.smallStrong.copyWith(color: AppColors.paprika700),
        secondaryLabelStyle: AppTextStyles.smallStrong.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        labelStyle: AppTextStyles.smallStrong,
        floatingLabelStyle: AppTextStyles.smallStrong.copyWith(color: AppColors.brand),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.focusRing, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: AppTextStyles.h3,
        contentTextStyle: AppTextStyles.body,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceInverse,
        contentTextStyle: AppTextStyles.small.copyWith(color: AppColors.textOnDark),
        actionTextColor: AppColors.paprika300,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
        linearTrackColor: AppColors.surfaceSunken,
        circularTrackColor: Colors.transparent,
        strokeCap: StrokeCap.round,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.brand,
        inactiveTrackColor: AppColors.surfaceSunken,
        thumbColor: AppColors.brand,
        overlayColor: AppColors.brand.withValues(alpha: 0.12),
        trackHeight: 6,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.sand400,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.brand
              : AppColors.surfaceSunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.transparent
              : AppColors.border,
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppColors.surfaceInverse,
          borderRadius: AppRadius.smAll,
        ),
        textStyle: AppTextStyles.caption.copyWith(color: AppColors.textOnDark),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textMuted,
        textColor: AppColors.textStrong,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: HangoutPageTransitionsBuilder(),
          TargetPlatform.iOS: HangoutPageTransitionsBuilder(),
          TargetPlatform.windows: HangoutPageTransitionsBuilder(),
          TargetPlatform.macOS: HangoutPageTransitionsBuilder(),
          TargetPlatform.linux: HangoutPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Route transition: Material's shared-axis (vertical) pattern in Hangout's
/// easing. The incoming screen rises a few pixels and fades in; the outgoing
/// one settles back. 300ms, never linear.
class HangoutPageTransitionsBuilder extends PageTransitionsBuilder {
  const HangoutPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(parent: animation, curve: AppMotion.easeOut);
    final exit = CurvedAnimation(parent: secondaryAnimation, curve: AppMotion.easeOut);

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: const Interval(0, 0.6, curve: AppMotion.easeOut)),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(enter),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0, -0.02),
          ).animate(exit),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.85).animate(exit),
            child: child,
          ),
        ),
      ),
    );
  }
}
