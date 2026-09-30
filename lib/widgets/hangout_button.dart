import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import 'hangout_motion.dart';

enum HangoutButtonVariant {
  /// Paprika fill + lift. The one primary action on a screen.
  primary,

  /// Soft paprika fill, paprika text. An accent action that isn't *the*
  /// action — "Start" beside each crew, "Join" next to "New crew".
  tonal,

  /// White surface, hairline border. Everything secondary.
  secondary,

  /// Avocado fill — confirmation only ("I'm in", "You're in ✓").
  fresh,

  /// No fill, no border. Lowest emphasis.
  ghost,

  /// Destructive confirmation. Solid, no lift.
  danger,
}

enum HangoutButtonSize { sm, md, lg }

/// The Hangout pill button — `components/core/Button.jsx`.
///
/// Every size keeps a 48dp touch target; `sm` draws a 40dp pill inside it.
class HangoutButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final HangoutButtonVariant variant;
  final HangoutButtonSize size;
  final IconData? iconLeft;
  final IconData? iconRight;
  final bool block;
  final bool loading;

  const HangoutButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = HangoutButtonVariant.primary,
    this.size = HangoutButtonSize.md,
    this.iconLeft,
    this.iconRight,
    this.block = false,
    this.loading = false,
  });

  double get _height => switch (size) {
        HangoutButtonSize.sm => 40,
        HangoutButtonSize.md => 48,
        HangoutButtonSize.lg => 56,
      };

  double get _padX => switch (size) {
        HangoutButtonSize.sm => 16,
        HangoutButtonSize.md => 20,
        HangoutButtonSize.lg => 28,
      };

  double get _fontSize => switch (size) {
        HangoutButtonSize.sm => 14.5,
        HangoutButtonSize.md => 15.5,
        HangoutButtonSize.lg => 17,
      };

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    final (Color bg, Color fg, BoxBorder? border, List<BoxShadow> shadow) =
        switch (variant) {
      HangoutButtonVariant.primary => (
          AppColors.brand,
          AppColors.textOnBrand,
          null,
          AppShadows.brand,
        ),
      HangoutButtonVariant.tonal => (
          AppColors.brandSoft,
          AppColors.paprika700,
          null,
          const <BoxShadow>[],
        ),
      HangoutButtonVariant.secondary => (
          AppColors.surface,
          AppColors.textStrong,
          Border.all(color: AppColors.borderStrong),
          const <BoxShadow>[],
        ),
      HangoutButtonVariant.fresh => (
          AppColors.accentFresh,
          Colors.white,
          null,
          AppShadows.fresh,
        ),
      HangoutButtonVariant.ghost => (
          Colors.transparent,
          AppColors.textStrong,
          null,
          const <BoxShadow>[],
        ),
      HangoutButtonVariant.danger => (
          AppColors.danger,
          Colors.white,
          null,
          const <BoxShadow>[],
        ),
    };

    final pill = AnimatedOpacity(
      duration: AppMotion.base,
      opacity: disabled && !loading ? 0.45 : 1,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.easeOut,
        height: _height,
        padding: EdgeInsets.symmetric(horizontal: _padX),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.pillAll,
          border: border,
          boxShadow: disabled ? const [] : shadow,
        ),
        child: Row(
          mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: _fontSize + 2,
                height: _fontSize + 2,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
              )
            else ...[
              if (iconLeft != null) ...[
                Icon(iconLeft, size: _fontSize + 3, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.button
                      .copyWith(fontSize: _fontSize, color: fg),
                ),
              ),
              if (iconRight != null) ...[
                const SizedBox(width: 8),
                Icon(iconRight, size: _fontSize + 3, color: fg),
              ],
            ],
          ],
        ),
      ),
    );

    Widget child = block ? SizedBox(width: double.infinity, child: pill) : pill;

    // Small pills keep a full 48dp hit area around the 40dp shape.
    if (size == HangoutButtonSize.sm) {
      child = SizedBox(height: 48, child: Center(widthFactor: 1, child: child));
    }

    return Semantics(
      button: true,
      enabled: !disabled,
      label: loading ? '$label, loading' : null,
      child: Pressable(onTap: disabled ? null : onPressed, child: child),
    );
  }
}

enum HangoutIconButtonVariant {
  /// No fill. The standard app-bar button (back, overflow).
  plain,

  /// White circle with a hairline border — floating over light content.
  surface,

  /// Paprika circle — the raised primary action.
  brand,

  /// Translucent white + blur. Only for controls floating over photography.
  glass,

  /// Avocado circle — "I'm in" on the swipe deck.
  fresh,
}

/// Round icon-only button — `components/core/IconButton.jsx`.
/// Presses spring to 0.9. Always at least a 48dp touch target.
class HangoutIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final HangoutIconButtonVariant variant;
  final double size;
  final Color? iconColor;
  final String? tooltip;

  const HangoutIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = HangoutIconButtonVariant.plain,
    this.size = 44,
    this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, BoxBorder? border, List<BoxShadow> shadow) =
        switch (variant) {
      HangoutIconButtonVariant.plain => (
          Colors.transparent,
          AppColors.textStrong,
          null,
          const <BoxShadow>[],
        ),
      HangoutIconButtonVariant.surface => (
          AppColors.surface,
          AppColors.textStrong,
          Border.all(color: AppColors.border),
          AppShadows.sm,
        ),
      HangoutIconButtonVariant.brand => (
          AppColors.brand,
          Colors.white,
          null,
          AppShadows.brand,
        ),
      HangoutIconButtonVariant.glass => (
          Colors.white.withValues(alpha: 0.22),
          Colors.white,
          Border.all(color: Colors.white.withValues(alpha: 0.4)),
          const <BoxShadow>[],
        ),
      HangoutIconButtonVariant.fresh => (
          AppColors.accentFresh,
          Colors.white,
          null,
          AppShadows.fresh,
        ),
    };

    Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border,
        boxShadow: onPressed == null ? const [] : shadow,
      ),
      child: Icon(
        icon,
        size: variant == HangoutIconButtonVariant.plain ? 24 : size * 0.44,
        color: iconColor ?? fg,
      ),
    );

    if (variant == HangoutIconButtonVariant.glass) {
      circle = ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: circle,
        ),
      );
    }

    final target = size < 48 ? 48.0 : size;
    Widget button = SizedBox(
      width: target,
      height: target,
      child: Center(child: circle),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return Semantics(
      button: true,
      label: tooltip,
      child: Opacity(
        opacity: onPressed == null ? 0.45 : 1,
        child: Pressable(onTap: onPressed, scale: 0.9, child: button),
      ),
    );
  }
}

/// Back button for top app bars. Honors the system back gesture by simply
/// popping the route.
class HangoutBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;

  const HangoutBackButton({
    super.key,
    this.onPressed,
    this.icon = Icons.arrow_back_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: HangoutIconButton(
        icon: icon,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

/// Sticky bottom action bar — the RSVP / confirm pattern at the foot of
/// detail views.
class StickyActionBar extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const StickyActionBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding.copyWith(
        bottom: padding.bottom + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: child,
    );
  }
}
