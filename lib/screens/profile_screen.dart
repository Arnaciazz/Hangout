import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/history_service.dart';
import '../services/profile_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/dino_avatar.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_list.dart';
import 'avatar_setup_screen.dart';

/// The signed-in person: who they are to their crews, and the account exits.
class ProfileScreen extends StatefulWidget {
  /// Bumped by the shell when this tab is re-entered.
  final int refreshToken;

  const ProfileScreen({super.key, this.refreshToken = 0});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profiles = ProfileService();
  final _history = HistoryService();

  Map<String, dynamic>? _profile;
  ({int hangouts, int crews})? _counts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen old) {
    super.didUpdateWidget(old);
    if (old.refreshToken != widget.refreshToken) _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _profiles.fetchProfile(),
      _history.fetchCounts(),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as Map<String, dynamic>?;
      _counts = results[1] as ({int hangouts, int crews});
    });
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => AvatarSetupScreen(
        initialNickname: _profile?['nickname'] as String?,
        initialAvatarId: _profile?['avatar_id'] as int?,
        onSetupComplete: () => Navigator.of(ctx).pop(),
      ),
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ProfileView(
          nickname: _profile?['nickname'] as String?,
          avatarId: _profile?['avatar_id'] as int?,
          photoUrl: user?.userMetadata?['avatar_url'] as String?,
          contact: user?.email ?? user?.phone,
          hangouts: _counts?.hangouts,
          crews: _counts?.crews,
          onEdit: _edit,
          onLogOut: () => AuthService().signOut(),
        ),
      ),
    );
  }
}

/// Pure presentation of the profile — renders with fixtures in tests.
/// A null count means "still loading".
class ProfileView extends StatelessWidget {
  final String? nickname;
  final int? avatarId;
  final String? photoUrl;
  final String? contact;
  final int? hangouts;
  final int? crews;
  final VoidCallback? onEdit;
  final VoidCallback? onLogOut;

  const ProfileView({
    super.key,
    this.nickname,
    this.avatarId,
    this.photoUrl,
    this.contact,
    this.hangouts,
    this.crews,
    this.onEdit,
    this.onLogOut,
  });

  @override
  Widget build(BuildContext context) {
    final name = nickname ?? '';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        MediaQuery.of(context).padding.top + AppSpacing.x5,
        AppSpacing.gutter,
        120,
      ),
      children: [
        Text('You', style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.x5),
        Row(
          children: [
            UserDinoAvatar(
              avatarId: avatarId,
              fallbackUrl: photoUrl,
              fallbackInitial: name.isNotEmpty ? name[0] : '?',
              size: 64,
            ),
            const SizedBox(width: AppSpacing.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? ' ' : '@$name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3,
                  ),
                  if (contact != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x6),
        Row(
          children: [
            Expanded(
              child: StatChip(
                label: 'Hangouts',
                value: hangouts?.toString() ?? '–',
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: StatChip(
                label: 'Crews',
                value: crews?.toString() ?? '–',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        HangoutListGroup(
          children: [
            HangoutListRow(
              leading: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
              title: 'Edit name and avatar',
              showChevron: true,
              onTap: onEdit,
            ),
            HangoutListRow(
              leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
              title: 'Log out',
              titleColor: AppColors.danger,
              onTap: onLogOut,
            ),
          ],
        ),
      ],
    );
  }
}
