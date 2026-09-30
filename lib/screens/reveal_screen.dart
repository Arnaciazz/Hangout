import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../models/group.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_avatar.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_list.dart';
import 'results_screen.dart';

/// After you've swiped: who's still going, and — for the host — the button
/// that reveals the winner. Everyone else lands on the results the moment the
/// host presses it.
///
/// There's no timer. The host decides when enough of the crew has voted.
class RevealScreen extends StatefulWidget {
  final SessionModel session;
  final Group group;
  final SessionService? service;

  const RevealScreen({
    super.key,
    required this.session,
    required this.group,
    this.service,
  });

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> {
  late final SessionService _service = widget.service ?? SessionService();
  StreamSubscription<CrewProgress>? _progressSub;
  StreamSubscription<String>? _statusSub;

  CrewProgress? _progress;
  bool _revealing = false;
  bool _navigating = false;

  String? get _myId => Supabase.instance.client.auth.currentUser?.id;
  bool get _amHost => widget.session.userId == _myId;

  @override
  void initState() {
    super.initState();
    _progressSub = _service
        .watchCrewProgress(widget.session.id, widget.group.id)
        .listen((p) {
      if (mounted) setState(() => _progress = p);
    }, onError: (_) {});
    _statusSub =
        _service.watchSessionStatus(widget.session.id).listen((status) {
      if (status == 'revealed' || status == 'completed') _showResults(null);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  void _showResults(List<PlaceResult>? results) {
    if (_navigating || !mounted) return;
    _navigating = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultsScreen(
        session: widget.session,
        group: widget.group,
        service: _service,
        precomputedResults: results,
        celebrate: true,
      ),
    ));
  }

  Future<void> _reveal() async {
    final l10n = context.l10n;
    final p = _progress;
    if (p != null && !p.allDone) {
      final waiting = p.total - p.finished;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.revealEarlyTitle),
          content: Text(l10n.revealEarlyBody(waiting), style: AppTextStyles.small),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.revealEarlyWait,
                  style: AppTextStyles.smallStrong
                      .copyWith(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.revealEarlyConfirm,
                  style:
                      AppTextStyles.smallStrong.copyWith(color: AppColors.brand)),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    setState(() => _revealing = true);
    HapticFeedback.mediumImpact();
    try {
      final results = await _service.computeResults(widget.session.id);
      _showResults(results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _revealing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.revealFailed),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = _progress;
    final done = p?.finished ?? 0;
    final total = p?.total ?? widget.group.members.length;
    final allDone = p?.allDone ?? false;

    final host = widget.group.members
        .where((m) => m.userId == widget.session.userId)
        .firstOrNull;
    final hostName = host?.displayName ?? l10n.revealTheHost;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: HangoutBackButton(
          icon: Icons.close_rounded,
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.x2,
          AppSpacing.gutter,
          AppSpacing.x8,
        ),
        children: [
          Text(
            allDone ? l10n.revealAllDoneTitle : l10n.revealWaitingTitle,
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: 4),
          Text(
            _amHost
                ? (allDone ? l10n.revealHostReady : l10n.revealHostEarly)
                : l10n.revealGuestBody(hostName),
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.x6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: total > 0 ? done / total : 0),
                    duration: AppMotion.slow,
                    curve: AppMotion.easeOut,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceSunken,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentFresh,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Text(l10n.revealProgress(done, total),
                  style: AppTextStyles.smallStrong),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          HangoutListGroup(
            children: [
              for (final m in widget.group.members) _memberRow(context, m),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _amHost
          ? StickyActionBar(
              child: HangoutButton(
                label: l10n.revealButton,
                size: HangoutButtonSize.lg,
                block: true,
                loading: _revealing,
                onPressed: p == null || done == 0 ? null : _reveal,
              ),
            )
          : null,
    );
  }

  Widget _memberRow(BuildContext context, GroupMember m) {
    final l10n = context.l10n;
    final finished = _progress?.hasFinished(m.userId) ?? false;
    final isMe = m.userId == _myId;
    final isHost = m.userId == widget.session.userId;

    return HangoutListRow(
      leading: HangoutAvatar(name: m.displayName, imageUrl: m.avatarUrl, size: 40),
      title: isMe ? l10n.nameYou(m.displayName) : m.displayName,
      subtitle: finished ? l10n.revealMemberDone : l10n.revealMemberSwiping,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHost) ...[
            HangoutBadge(label: l10n.badgeHost, tone: BadgeTone.warm),
            const SizedBox(width: AppSpacing.x2),
          ],
          AnimatedSwitcher(
            duration: AppMotion.base,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: finished
                ? const Icon(Icons.check_circle_rounded,
                    key: ValueKey(true), color: AppColors.accentFresh)
                : const Icon(Icons.radio_button_unchecked_rounded,
                    key: ValueKey(false), color: AppColors.sand300),
          ),
        ],
      ),
    );
  }
}
