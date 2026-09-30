import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../services/bill_service.dart';
import '../services/history_service.dart';
import '../services/profile_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../utils/money.dart';
import '../widgets/dino_avatar.dart';
import '../widgets/hangout_button.dart';
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
  final _bills = BillService();

  Map<String, dynamic>? _profile;
  ({int hangouts, int crews})? _counts;
  String? _upi;

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
    final (profile, counts, upi) = await (
      _profiles.fetchProfile(),
      _history.fetchCounts(),
      _bills.getMyUpi().catchError((_) => null),
    ).wait;
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _counts = counts;
      _upi = upi;
    });
  }

  Future<void> _editUpi() async {
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpiSheet(initial: _upi, service: _bills),
    );
    if (saved != null && mounted) setState(() => _upi = saved);
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
          upiId: _upi,
          onEdit: _edit,
          onEditUpi: _editUpi,
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
  final String? upiId;
  final VoidCallback? onEdit;
  final VoidCallback? onEditUpi;
  final VoidCallback? onLogOut;

  const ProfileView({
    super.key,
    this.nickname,
    this.avatarId,
    this.photoUrl,
    this.contact,
    this.hangouts,
    this.crews,
    this.upiId,
    this.onEdit,
    this.onEditUpi,
    this.onLogOut,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
        Text(l10n.profileTitle, style: AppTextStyles.h1),
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
                label: l10n.profileHangouts,
                value: hangouts?.toString() ?? '–',
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: StatChip(
                label: l10n.profileCrews,
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
              title: l10n.profileEdit,
              showChevron: true,
              onTap: onEdit,
            ),
            HangoutListRow(
              leading: const Icon(Icons.currency_rupee_rounded,
                  color: AppColors.textMuted),
              title: upiId ?? l10n.profileUpiAdd,
              subtitle: l10n.profileUpiHint,
              showChevron: true,
              onTap: onEditUpi,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        HangoutListGroup(
          children: [
            HangoutListRow(
              leading: const Icon(Icons.description_outlined,
                  color: AppColors.textMuted),
              title: l10n.profileLicences,
              showChevron: true,
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.appName,
              ),
            ),
            HangoutListRow(
              leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
              title: l10n.profileLogOut,
              titleColor: AppColors.danger,
              onTap: onLogOut,
            ),
          ],
        ),
      ],
    );
  }
}

/// Where friends pay you back when you cover a bill.
class _UpiSheet extends StatefulWidget {
  final String? initial;
  final BillService service;

  const _UpiSheet({required this.initial, required this.service});

  @override
  State<_UpiSheet> createState() => _UpiSheetState();
}

class _UpiSheetState extends State<_UpiSheet> {
  late final _ctrl = TextEditingController(text: widget.initial ?? '');
  bool _showError = false;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _ctrl.text.trim();
    if (!isValidUpiId(value)) {
      setState(() => _showError = true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.saveMyUpi(value);
      if (mounted) Navigator.of(context).pop(value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorGeneric)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: HangoutSheet(
        title: l10n.billUpiLabel,
        subtitle: l10n.profileUpiSheetBody,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => _save(),
              onChanged: (_) {
                if (_showError) setState(() => _showError = false);
              },
              decoration: InputDecoration(
                hintText: l10n.billUpiHint,
                errorMaxLines: 2,
                errorText: _showError ? l10n.billUpiError : null,
              ),
            ),
            const SizedBox(height: AppSpacing.x5),
            HangoutButton(
              label: l10n.actionSave,
              size: HangoutButtonSize.lg,
              block: true,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
