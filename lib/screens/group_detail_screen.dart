import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/group.dart';
import '../services/group_service.dart';
import '../services/history_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_avatar.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_list.dart';
import 'group_session_lobby_screen.dart';
import 'place_swipe_screen.dart';
import 'session_filters_screen.dart';
import 'session_setup_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _service = GroupService();
  final _sessionService = SessionService();
  late Group _group;
  bool _loadingCode = false;

  SessionSummary? _activeSession;
  List<SessionSummary> _pastSessions = [];
  bool _loadingSessions = true;

  String get _myId => Supabase.instance.client.auth.currentUser!.id;
  bool get _amOwner => _group.isOwner(_myId);
  bool get _isHunger => _group.mode == 'hunger';

  IconData get _modeIcon =>
      _isHunger ? Icons.restaurant_rounded : Icons.explore_rounded;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final active = await _sessionService.getActiveSessions(_group.id);
      final past = await _sessionService.getPastSessions(_group.id);
      if (mounted) {
        setState(() {
          _activeSession = active.isNotEmpty ? active.first : null;
          _pastSessions = past;
          _loadingSessions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSessions = false);
    }
  }

  Future<void> _openActiveSession() async {
    final s = _activeSession;
    if (s == null) return;

    if (s.status == 'setup') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GroupSessionLobbyScreen(
          sessionId: s.id,
          group: _group,
          mode: _group.mode,
          filters: const SwipeFilters(),
        ),
      ));
    } else if (s.status == 'swiping') {
      try {
        final session = await _sessionService.getSessionWithPlaces(s.id);
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlaceSwipeScreen(session: session, group: _group),
        ));
      } catch (e) {
        if (mounted) _showError("Couldn't load that session.");
      }
    } else if (s.status == 'revealed') {
      try {
        final session = await _sessionService.getSessionWithPlaces(s.id);
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ResultsScreen(
            session: session,
            group: _group,
            service: _sessionService,
          ),
        ));
      } catch (e) {
        if (mounted) _showError("Couldn't load the results.");
      }
    }
  }

  Future<void> _refreshCode() async {
    setState(() => _loadingCode = true);
    try {
      final newCode = await _service.refreshInviteCode(_group.id);
      setState(() {
        _group = Group(
          id: _group.id,
          name: _group.name,
          mode: _group.mode,
          createdBy: _group.createdBy,
          inviteCode: newCode,
          createdAt: _group.createdAt,
          members: _group.members,
        );
      });
    } catch (_) {
      _showError("Couldn't refresh that code.");
    } finally {
      if (mounted) setState(() => _loadingCode = false);
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _group.inviteCode));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Code copied'),
      duration: Duration(seconds: 2),
    ));
  }

  Future<void> _shareWhatsApp() async {
    final message = Uri.encodeComponent(
      'Join my Hangout crew *${_group.name}*\n\n'
      'Invite code: *${_group.inviteCode}*\n\n'
      'Get Hangout and punch in the code.',
    );
    final uri = Uri.parse('whatsapp://send?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    await Clipboard.setData(ClipboardData(
      text: 'Join my Hangout crew "${_group.name}" — code: ${_group.inviteCode}',
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("WhatsApp isn't installed — invite copied instead"),
    ));
  }

  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_amOwner ? 'Delete this crew?' : 'Leave this crew?'),
        content: Text(
          _amOwner
              ? 'This removes "${_group.name}" for everyone.'
              : 'You\'ll drop out of "${_group.name}".',
          style: AppTextStyles.small,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppTextStyles.smallStrong
                    .copyWith(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_amOwner ? 'Delete' : 'Leave',
                style: AppTextStyles.smallStrong
                    .copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      if (_amOwner) {
        await _service.deleteGroup(_group.id);
      } else {
        await _service.leaveGroup(_group.id);
      }
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final n = _group.memberCount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: const HangoutBackButton(),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (_) => _confirmLeave(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'leave',
                child: Text(
                  _amOwner ? 'Delete crew' : 'Leave crew',
                  style: AppTextStyles.body.copyWith(color: AppColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSessions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, AppSpacing.x2, AppSpacing.gutter, AppSpacing.x10),
          children: [
            Text(_group.name, style: AppTextStyles.h1),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(_modeIcon, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  '${_isHunger ? 'Food' : 'Places'} · $n ${n == 1 ? 'person' : 'people'}',
                  style: AppTextStyles.small,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x6),
            _buildSession(),
            const SizedBox(height: AppSpacing.x8),
            const SectionHeader(title: 'Invite'),
            const SizedBox(height: AppSpacing.x2),
            _buildInvite(),
            const SizedBox(height: AppSpacing.x8),
            const SectionHeader(title: 'The crew'),
            const SizedBox(height: AppSpacing.x2),
            HangoutListGroup(
              children: [
                for (final m in _group.members)
                  HangoutListRow(
                    leading: HangoutAvatar(
                      name: m.displayName,
                      imageUrl: m.avatarUrl,
                      size: 40,
                    ),
                    title: m.displayName,
                    trailing: m.userId == _myId
                        ? const HangoutBadge(label: 'You', tone: BadgeTone.neutral)
                        : (m.isOwner
                            ? const HangoutBadge(label: 'Host', tone: BadgeTone.warm)
                            : null),
                  ),
              ],
            ),
            if (_pastSessions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x8),
              const SectionHeader(title: 'Past hangouts'),
              const SizedBox(height: AppSpacing.x2),
              HangoutListGroup(
                children: [
                  for (final p in _pastSessions)
                    HangoutListRow(
                      leading: SizedBox(
                        width: 40,
                        child: Icon(
                          p.mode == 'hunger'
                              ? Icons.restaurant_rounded
                              : Icons.explore_rounded,
                          color: AppColors.textMuted,
                        ),
                      ),
                      title: p.mode == 'hunger' ? 'Food' : 'Places',
                      subtitle: friendlyDate(p.completedAt ?? p.createdAt),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The crew's one job: the session in progress, or the button to start one.
  Widget _buildSession() {
    if (_loadingSessions) {
      return Container(
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.surfaceSunken,
          borderRadius: AppRadius.pillAll,
        ),
      );
    }

    final s = _activeSession;
    if (s == null) {
      return HangoutButton(
        label: _isHunger ? 'Find somewhere to eat' : 'Find somewhere to go',
        iconLeft: _modeIcon,
        size: HangoutButtonSize.lg,
        block: true,
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SessionSetupScreen(
              group: _group,
              mode: _isHunger ? 'hunger' : 'travel',
            ),
          ));
          _loadSessions();
        },
      );
    }

    final (String state, String action) = switch (s.status) {
      'setup' => ('Waiting for everyone to drop a pin', 'Open'),
      'swiping' => ('Swiping has started', 'Swipe'),
      'revealed' => ('The results are in', 'See results'),
      _ => ('In progress', 'Open'),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.paprika100),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isHunger ? 'Picking somewhere to eat' : 'Picking somewhere to go',
                  style: AppTextStyles.bodyStrong,
                ),
                const SizedBox(height: 2),
                Text(state, style: AppTextStyles.small),
              ],
            ),
          ),
          HangoutButton(
            label: action,
            size: HangoutButtonSize.sm,
            onPressed: _openActiveSession,
          ),
        ],
      ),
    );
  }

  Widget _buildInvite() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 6, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'Invite code ${_group.inviteCode.split('').join(' ')}',
                      child: ExcludeSemantics(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _group.inviteCode,
                            style: AppTextStyles.statNumber(30)
                                .copyWith(letterSpacing: 6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Friends join with this code',
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              HangoutIconButton(
                icon: Icons.copy_rounded,
                tooltip: 'Copy code',
                onPressed: _copyCode,
              ),
              HangoutIconButton(
                icon: Icons.share_rounded,
                tooltip: 'Share invite',
                onPressed: _shareWhatsApp,
              ),
            ],
          ),
          if (_amOwner) ...[
            const SizedBox(height: 4),
            HangoutButton(
              label: _loadingCode ? 'Getting a new code…' : 'Get a new code',
              size: HangoutButtonSize.sm,
              variant: HangoutButtonVariant.ghost,
              iconLeft: Icons.refresh_rounded,
              onPressed: _loadingCode ? null : _refreshCode,
            ),
          ],
        ],
      ),
    );
  }
}
