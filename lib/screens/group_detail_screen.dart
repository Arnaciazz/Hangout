import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../utils/dates.dart';
import '../utils/links.dart';
import '../widgets/hangout_avatar.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_list.dart';
import 'group_session_lobby_screen.dart';
import 'place_swipe_screen.dart';
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
      final (active, past) = await (
        _sessionService.getActiveSessions(_group.id),
        _sessionService.getPastSessions(_group.id),
      ).wait;
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

  /// Back into the session where it stands: the lobby, the deck (picking up
  /// after your last swipe), or the reveal.
  Future<void> _openActiveSession() async {
    final s = _activeSession;
    if (s == null) return;

    final SessionModel session;
    try {
      session = await _sessionService.getSessionWithPlaces(s.id);
    } catch (_) {
      if (mounted) _showError(context.l10n.crewSessionLoadFailed);
      return;
    }
    if (!mounted) return;

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => switch (session.status) {
        'setup' => GroupSessionLobbyScreen(
            sessionId: session.id,
            group: _group,
            mode: session.mode,
            filters: session.filters,
            hostId: session.userId,
          ),
        'swiping' => PlaceSwipeScreen(
            session: session,
            group: _group,
            service: _sessionService,
            resume: true,
          ),
        _ => ResultsScreen(
            session: session,
            group: _group,
            service: _sessionService,
          ),
      },
    ));
    _loadSessions();
  }

  void _openPast(SessionSummary p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultsScreen(
        session: SessionModel(
          id: p.id,
          groupId: _group.id,
          userId: p.hostId ?? '',
          mode: p.mode,
          type: 'group',
          status: p.status,
        ),
        group: _group,
        service: _sessionService,
      ),
    ));
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
      if (mounted) _showError(context.l10n.crewCodeRefreshFailed);
    } finally {
      if (mounted) setState(() => _loadingCode = false);
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _group.inviteCode));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.l10n.crewCodeCopied),
      duration: const Duration(seconds: 2),
    ));
  }

  /// WhatsApp if it's there; the invite goes to the clipboard either way, so
  /// it can be pasted anywhere.
  Future<void> _shareInvite() async {
    final l10n = context.l10n;
    final text = l10n.crewInviteMessage(_group.name, _group.inviteCode);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    await openLink(
      context,
      whatsAppShareUri(text),
      failMessage: l10n.crewInviteCopied,
    );
  }

  Future<void> _confirmLeave() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_amOwner ? l10n.crewDeleteTitle : l10n.crewLeaveTitle),
        content: Text(
          _amOwner
              ? l10n.crewDeleteBody(_group.name)
              : l10n.crewLeaveBody(_group.name),
          style: AppTextStyles.small,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel,
                style: AppTextStyles.smallStrong
                    .copyWith(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_amOwner ? l10n.actionDelete : l10n.crewLeave,
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
    } catch (_) {
      if (mounted) _showError(context.l10n.errorGeneric);
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
    final l10n = context.l10n;
    final n = _group.memberCount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: const HangoutBackButton(),
        actions: [
          PopupMenuButton<String>(
            tooltip: l10n.actionMore,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (_) => _confirmLeave(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'leave',
                child: Text(
                  _amOwner ? l10n.crewDeleteMenu : l10n.crewLeaveMenu,
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
                  _isHunger ? l10n.crewMetaFood(n) : l10n.crewMetaPlaces(n),
                  style: AppTextStyles.small,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x6),
            _buildSession(),
            const SizedBox(height: AppSpacing.x8),
            SectionHeader(title: l10n.crewInviteTitle),
            const SizedBox(height: AppSpacing.x2),
            _buildInvite(),
            const SizedBox(height: AppSpacing.x8),
            SectionHeader(title: l10n.crewMembersTitle),
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
                        ? HangoutBadge(label: l10n.badgeYou, tone: BadgeTone.neutral)
                        : (m.isOwner
                            ? HangoutBadge(label: l10n.badgeOwner, tone: BadgeTone.warm)
                            : null),
                  ),
              ],
            ),
            if (_pastSessions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x8),
              SectionHeader(title: l10n.crewPastTitle),
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
                      title: p.winnerName ?? l10n.memoryNoWinner,
                      subtitle: friendlyDate(
                        l10n,
                        p.completedAt ?? p.createdAt,
                      ),
                      showChevron: true,
                      onTap: () => _openPast(p),
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
    final l10n = context.l10n;
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
        label: _isHunger ? l10n.crewFindFood : l10n.crewFindPlace,
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
      'setup' => (l10n.crewSessionSetup, l10n.crewSessionOpen),
      _ => (l10n.crewSessionSwiping, l10n.crewSessionSwipe),
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
                  _isHunger ? l10n.crewPickingFood : l10n.crewPickingPlace,
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
    final l10n = context.l10n;
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
                      label: l10n.crewInviteCodeSemantics(
                          _group.inviteCode.split('').join(' ')),
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
                    Text(l10n.crewInviteHint, style: AppTextStyles.caption),
                  ],
                ),
              ),
              HangoutIconButton(
                icon: Icons.copy_rounded,
                tooltip: l10n.crewCopyCode,
                onPressed: _copyCode,
              ),
              HangoutIconButton(
                icon: Icons.share_rounded,
                tooltip: l10n.crewShareInvite,
                onPressed: _shareInvite,
              ),
            ],
          ),
          if (_amOwner) ...[
            const SizedBox(height: 4),
            HangoutButton(
              label: _loadingCode ? l10n.crewNewCodeLoading : l10n.crewNewCode,
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
