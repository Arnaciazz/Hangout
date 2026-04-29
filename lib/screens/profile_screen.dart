import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/user_profile.dart';
import '../widgets/bento_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const u = SampleUser.alex;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(children: [
        _profileHeader(u),
        const SizedBox(height: 24),
        _statsRow(u),
        const SizedBox(height: 20),
        _achievementsCard(),
        const SizedBox(height: 20),
        _menuList(),
      ]),
    );
  }

  Widget _profileHeader(UserProfile u) {
    return Column(children: [
      Container(
        width: 96, height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.purpleGradient,
          border: Border.all(color: AppColors.secondaryPurple, width: 3),
          boxShadow: [BoxShadow(color: AppColors.secondaryPurple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(child: Text('A', style: AppTextStyles.headlineLarge.copyWith(color: Colors.white))),
      ),
      const SizedBox(height: 16),
      Text(u.name, style: AppTextStyles.headlineLarge),
      const SizedBox(height: 4),
      Text(u.title, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.outline)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.greenGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text('${u.membershipTier} Member', style: AppTextStyles.labelBold.copyWith(color: Colors.white)),
        ]),
      ),
    ]);
  }

  Widget _statsRow(UserProfile u) {
    return Row(children: [
      Expanded(child: BentoCard(borderRadius: 24, padding: const EdgeInsets.all(16), child: Column(children: [
        Text('🎯', style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text('${u.decisionsCount}', style: AppTextStyles.headlineMedium),
        Text('Decisions', style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline)),
      ]))),
      const SizedBox(width: 10),
      Expanded(child: BentoCard(borderRadius: 24, padding: const EdgeInsets.all(16), child: Column(children: [
        Text('🔥', style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text('${u.streakDays}', style: AppTextStyles.headlineMedium),
        Text('Day Streak', style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline)),
      ]))),
      const SizedBox(width: 10),
      Expanded(child: BentoCard(borderRadius: 24, padding: const EdgeInsets.all(16), child: Column(children: [
        Text('👥', style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text('${u.friendsCount}', style: AppTextStyles.headlineMedium),
        Text('Friends', style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline)),
      ]))),
    ]);
  }

  Widget _achievementsCard() {
    return BentoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ACHIEVEMENTS', style: AppTextStyles.labelBold.copyWith(color: AppColors.outline, letterSpacing: 1.5)),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _badge('🏆', 'Top Picker', true),
        _badge('⚡', 'Speed', true),
        _badge('🌟', 'Explorer', true),
        _badge('🎪', 'Host', false),
      ]),
    ]));
  }

  Widget _badge(String emoji, String label, bool unlocked) {
    return Opacity(opacity: unlocked ? 1 : 0.35, child: Column(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: unlocked ? AppColors.primaryGreen.withOpacity(0.1) : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: unlocked ? AppColors.primaryGreen.withOpacity(0.3) : AppColors.cardBorder, width: 2),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
      ),
      const SizedBox(height: 6),
      Text(label, style: AppTextStyles.labelSmall.copyWith(color: unlocked ? AppColors.onSurface : AppColors.outline)),
    ]));
  }

  Widget _menuList() {
    final items = [
      (Icons.dashboard_rounded, 'Dashboard', AppColors.primaryGreen),
      (Icons.timer_rounded, 'Active Sessions', AppColors.secondaryPurple),
      (Icons.history_rounded, 'History', AppColors.tertiaryOrange),
      (Icons.payments_rounded, 'Expenses', AppColors.primaryGreen),
      (Icons.settings_rounded, 'Settings', AppColors.outline),
    ];
    return Column(children: items.map((item) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BentoCard(
        borderRadius: 24, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        onTap: () => HapticFeedback.selectionClick(),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: item.$3.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(item.$1, color: item.$3, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(item.$2, style: AppTextStyles.labelBold)),
          const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
        ]),
      ),
    )).toList());
  }
}
