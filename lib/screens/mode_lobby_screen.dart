import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'session_setup_screen.dart';

/// Shown when the user taps "Hungry?" or "Adventure?" on the home screen.
/// Lists groups in the matching mode, and lets them go solo or create a group.
class ModeLobbyScreen extends StatelessWidget {
  final String mode; // 'hunger' | 'travel'

  const ModeLobbyScreen({super.key, required this.mode});

  bool get _isHunger => mode == 'hunger';
  Color get _accent => _isHunger ? const Color(0xFF1B6D01) : const Color(0xFFA83300);
  Color get _accentBg => _isHunger ? const Color(0xFFE8FDD8) : const Color(0xFFFFEDE8);
  String get _emoji => _isHunger ? '🍽️' : '🌍';
  String get _title => _isHunger ? 'Hungry?' : 'Adventure?';
  String get _subtitle => _isHunger
      ? 'Find the perfect restaurant with your crew'
      : 'Explore amazing places together';

  @override
  Widget build(BuildContext context) {
    final service = GroupService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    _title,
                    style: AppTextStyles.display.copyWith(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),

            // ── Go Solo button ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _SoloCard(mode: mode, accent: _accent, accentBg: _accentBg),
            ),

            const SizedBox(height: 24),

            // ── My groups in this mode ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'With a Group',
                    style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CreateGroupScreen(preselectedMode: mode),
                    )),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _accentBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 16, color: _accent),
                          const SizedBox(width: 4),
                          Text(
                            'New Group',
                            style: AppTextStyles.labelSmall.copyWith(color: _accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Group list ─────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<Group>>(
                stream: service.watchMyGroups(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final all = snap.data ?? [];
                  final groups = all.where((g) => g.mode == mode).toList();
                  if (groups.isEmpty) {
                    return _EmptyGroups(
                      mode: mode,
                      accent: _accent,
                      accentBg: _accentBg,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _GroupTile(
                      group: groups[i],
                      accent: _accent,
                      accentBg: _accentBg,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(group: groups[i]),
                      )),
                      onStartSession: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SessionSetupScreen(group: groups[i], mode: mode),
                      )),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Solo card ────────────────────────────────────────────────────────────────

class _SoloCard extends StatelessWidget {
  final String mode;
  final Color accent;
  final Color accentBg;
  const _SoloCard({required this.mode, required this.accent, required this.accentBg});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SessionSetupScreen(group: null, mode: mode),
        ));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: accent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Go Solo',
                    style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
                  ),
                  Text(
                    'Just you — swipe and decide',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Group tile ───────────────────────────────────────────────────────────────

class _GroupTile extends StatelessWidget {
  final Group group;
  final Color accent;
  final Color accentBg;
  final VoidCallback onTap;
  final VoidCallback onStartSession;

  const _GroupTile({
    required this.group,
    required this.accent,
    required this.accentBg,
    required this.onTap,
    required this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  group.mode == 'hunger' ? '🍽️' : '🌍',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurface, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onStartSession();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: AppTextStyles.labelBold,
              ),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyGroups extends StatelessWidget {
  final String mode;
  final Color accent;
  final Color accentBg;
  const _EmptyGroups({required this.mode, required this.accent, required this.accentBg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: accentBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('👥', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'No groups yet',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a group and invite friends to decide together',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CreateGroupScreen(preselectedMode: mode),
              )),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create a Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
