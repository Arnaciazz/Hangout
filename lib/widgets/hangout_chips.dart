import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import 'hangout_motion.dart';

enum BadgeTone { brand, fresh, rating, soft, neutral, dark, warm, danger }

/// Small status/count pill — `components/core/Badge.jsx`.
/// Ratings, "New", headcounts, category flags.
class HangoutBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final IconData? icon;

  const HangoutBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.brand,
    this.icon,
  });

  /// The signature honey-star rating chip.
  factory HangoutBadge.rating(double value) => HangoutBadge(
        label: value.toStringAsFixed(1),
        tone: BadgeTone.rating,
        icon: Icons.star_rounded,
      );

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, List<BoxShadow> shadow) = switch (tone) {
      BadgeTone.brand => (AppColors.brand, Colors.white, const <BoxShadow>[]),
      BadgeTone.fresh => (AppColors.accentFresh, Colors.white, const <BoxShadow>[]),
      BadgeTone.rating => (Colors.white, AppColors.textStrong, AppShadows.sm),
      BadgeTone.soft => (AppColors.brandSoft, AppColors.paprika700, const <BoxShadow>[]),
      BadgeTone.neutral => (AppColors.surfaceSunken, AppColors.textBody, const <BoxShadow>[]),
      BadgeTone.dark => (AppColors.surfaceInverse, Colors.white, const <BoxShadow>[]),
      BadgeTone.warm => (AppColors.honey100, AppColors.honey600, const <BoxShadow>[]),
      BadgeTone.danger => (AppColors.danger, Colors.white, const <BoxShadow>[]),
    };

    final iconColor = tone == BadgeTone.rating ? AppColors.rating : fg;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillAll,
        boxShadow: shadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.captionStrong.copyWith(color: fg, height: 1),
          ),
        ],
      ),
    );
  }
}

enum TagTone { soft, fresh, honey, outline }

/// Category / cuisine tag — softer than a badge, used inline in cards.
class HangoutTag extends StatelessWidget {
  final String label;
  final TagTone tone;
  final IconData? icon;

  const HangoutTag({
    super.key,
    required this.label,
    this.tone = TagTone.soft,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color borderColor) = switch (tone) {
      TagTone.soft => (AppColors.brandTint, AppColors.paprika700, AppColors.paprika100),
      TagTone.fresh => (AppColors.accentFreshTint, AppColors.avocado700, AppColors.avocado100),
      TagTone.honey => (AppColors.honey100, AppColors.honey600, Colors.transparent),
      TagTone.outline => (Colors.transparent, AppColors.textBody, AppColors.borderStrong),
    };

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(label, style: AppTextStyles.small.copyWith(color: fg, height: 1)),
        ],
      ),
    );
  }
}

/// Bordered mini-stat box — the Distance / Rating / Price triad under a hero.
class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  final IconData? icon;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.accent = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accent ? AppColors.brandTint : AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: accent ? AppColors.paprika100 : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
              ],
              // Flexible so a long label ellipsises in a narrow triad rather
              // than overflowing the chip.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.title.copyWith(
              color: accent ? AppColors.brand : AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

/// Row title with an optional trailing affordance ("See all").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.h3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing!,
        if (trailing == null && action != null)
          Pressable(
            onTap: onAction,
            scale: 0.94,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action!,
                    style: AppTextStyles.smallStrong.copyWith(color: AppColors.brand),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.brand),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Horizontal category filter. `pill` for compact filter rails, `underline`
/// for primary in-page tabs with a sliding paprika indicator.
class FilterTabs extends StatelessWidget {
  final List<String> tabs;
  final String value;
  final ValueChanged<String> onChanged;
  final bool pill;
  final EdgeInsets padding;

  const FilterTabs({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
    this.pill = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final t in tabs)
            Padding(
              padding: EdgeInsets.only(right: pill ? 8 : 22),
              child: _Tab(
                label: t,
                active: t == value,
                pill: pill,
                onTap: () => onChanged(t),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final bool pill;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.active,
    required this.pill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (pill) {
      return Pressable(
        onTap: onTap,
        scale: 0.94,
        // No `alignment:` — see the note in session_filters_screen; an aligned
        // Container child expands to the incoming max width, which stretches
        // the pill instead of hugging its label.
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.brand : AppColors.surfaceSunken,
            borderRadius: AppRadius.pillAll,
          ),
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.base,
            style: AppTextStyles.smallStrong.copyWith(
              color: active ? Colors.white : AppColors.textBody,
              height: 1,
            ),
            child: Text(label),
          ),
        ),
      );
    }

    return Pressable(
      onTap: onTap,
      scale: 0.96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedDefaultTextStyle(
            duration: AppMotion.base,
            style: AppTextStyles.body.copyWith(
              fontSize: 16,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.textStrong : AppColors.textFaint,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
              child: Text(label),
            ),
          ),
          AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.spring,
            height: 3,
            width: active ? 28 : 0,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
