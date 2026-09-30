import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import 'hangout_motion.dart';

/// Bottom tab bar with a raised paprika centre action — the fixed navigation
/// pattern from `components/navigation/BottomNav.jsx`.
///
/// The bar is a solid white sheet with a generous top-corner radius and an
/// upward warm shadow; the centre action floats above it with a brand glow.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItemSpec>? items;

  /// Optional raised centre action, inserted at the midpoint of the tab row.
  final VoidCallback? onCenterAction;
  final IconData centerIcon;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items,
    this.onCenterAction,
    this.centerIcon = Icons.add_rounded,
  });

  static List<NavItemSpec> defaultItems(AppLocalizations l10n) => [
        NavItemSpec(Icons.home_outlined, Icons.home_rounded, l10n.navHome),
        NavItemSpec(Icons.group_outlined, Icons.group_rounded, l10n.navCrews),
        NavItemSpec(
            Icons.history_rounded, Icons.history_rounded, l10n.navMemories),
        NavItemSpec(
            Icons.person_outline_rounded, Icons.person_rounded, l10n.navYou),
      ];

  @override
  Widget build(BuildContext context) {
    final items = this.items ?? defaultItems(context.l10n);
    final hasCenter = onCenterAction != null;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final centerAfter = (items.length / 2).floor() - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: AppShadows.navBar,
      ),
      child: SizedBox(
        height: 70,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _NavItem(
                spec: items[i],
                selected: currentIndex == i,
                onTap: () => onTap(i),
              ),
              if (hasCenter && i == centerAfter)
                _CenterAction(icon: centerIcon, onTap: onCenterAction!),
            ],
          ],
        ),
      ),
    );
  }
}

class NavItemSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItemSpec(this.icon, this.activeIcon, this.label);
}

class _NavItem extends StatelessWidget {
  final NavItemSpec spec;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.paprika600 : AppColors.textMuted;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: spec.label,
        excludeSemantics: true,
        child: Pressable(
          scale: 0.9,
          haptics: false,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Material's active indicator: a soft paprika pill behind the icon.
              AnimatedContainer(
                duration: AppMotion.base,
                curve: AppMotion.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.brandTint : Colors.transparent,
                  borderRadius: AppRadius.pillAll,
                ),
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  transitionBuilder:
                      (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    selected ? spec.activeIcon : spec.icon,
                    key: ValueKey(selected),
                    size: 22,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: AppMotion.base,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12,
                  height: 1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
                child: Text(
                  spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CenterAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Semantics(
        button: true,
        label: context.l10n.navStartHangout,
        child: Pressable(
          scale: 0.9,
          onTap: onTap,
          child: Transform.translate(
            offset: const Offset(0, -14),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 4),
                boxShadow: AppShadows.brand,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
