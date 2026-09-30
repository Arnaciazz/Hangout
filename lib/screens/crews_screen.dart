import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_avatar.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_list.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';

/// The people you decide with: every crew you're in, and the two ways into a
/// new one — start it, or join with a friend's code.
class CrewsScreen extends StatefulWidget {
  const CrewsScreen({super.key});

  @override
  State<CrewsScreen> createState() => _CrewsScreenState();
}

class _CrewsScreenState extends State<CrewsScreen> {
  final _service = GroupService();
  late Stream<List<Group>> _groups = _service.watchMyGroups();

  Future<void> _refresh() async {
    setState(() => _groups = _service.watchMyGroups());
  }

  void _create() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
  }

  void _join() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JoinCrewSheet(service: _service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: StreamBuilder<List<Group>>(
        stream: _groups,
        builder:
            (context, snapshot) => CrewsView(
              crews: snapshot.data,
              failed: snapshot.hasError,
              onCreate: _create,
              onJoin: _join,
              onRetry: _refresh,
              onOpen:
                  (g) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GroupDetailScreen(group: g),
                    ),
                  ),
            ),
      ),
    );
  }
}

/// Pure presentation of the Crews tab. `crews == null` means still loading.
class CrewsView extends StatelessWidget {
  final List<Group>? crews;
  final bool failed;
  final VoidCallback? onCreate;
  final VoidCallback? onJoin;
  final VoidCallback? onRetry;
  final ValueChanged<Group>? onOpen;

  const CrewsView({
    super.key,
    required this.crews,
    this.failed = false,
    this.onCreate,
    this.onJoin,
    this.onRetry,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final Widget list;
    if (failed) {
      list = _CrewsError(onRetry: onRetry ?? () {});
    } else if (crews == null) {
      list = const _CrewsSkeleton();
    } else if (crews!.isEmpty) {
      list = _NoCrews(onCreate: onCreate ?? () {}, onJoin: onJoin ?? () {});
    } else {
      list = HangoutListGroup(
        children: [
          for (final g in crews!)
            HangoutListRow(
              leading: HangoutAvatar(name: g.name, size: 40),
              title: g.name,
              subtitle: crewMeta(context.l10n, g),
              showChevron: true,
              onTap: onOpen == null ? null : () => onOpen!(g),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          MediaQuery.of(context).padding.top + AppSpacing.x5,
          AppSpacing.gutter,
          120,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(context.l10n.crewsTitle, style: AppTextStyles.h1),
              ),
              HangoutButton(
                label: context.l10n.crewsJoin,
                size: HangoutButtonSize.sm,
                variant: HangoutButtonVariant.ghost,
                onPressed: onJoin,
              ),
              HangoutButton(
                label: context.l10n.crewsNew,
                iconLeft: Icons.add_rounded,
                size: HangoutButtonSize.sm,
                variant: HangoutButtonVariant.tonal,
                onPressed: onCreate,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(context.l10n.crewsSubtitle, style: AppTextStyles.small),
          const SizedBox(height: AppSpacing.x5),
          list,
        ],
      ),
    );
  }
}

/// "Food · 4 people"
String crewMeta(AppLocalizations l10n, Group g) => g.mode == 'hunger'
    ? l10n.crewMetaFood(g.memberCount)
    : l10n.crewMetaPlaces(g.memberCount);

// ─── Crew list states ─────────────────────────────────────────────────────────

class _CrewsSkeleton extends StatelessWidget {
  const _CrewsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(h / 2),
      ),
    );

    Widget row() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSunken,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [bar(140, 12), const SizedBox(height: 8), bar(90, 10)],
          ),
        ],
      ),
    );

    return Semantics(
      label: context.l10n.crewsLoading,
      child: HangoutListGroup(children: [row(), row()]),
    );
  }
}

class _NoCrews extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _NoCrews({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.crewsEmptyTitle, style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(context.l10n.crewsEmptyBody, style: AppTextStyles.small),
          const SizedBox(height: AppSpacing.x4),
          Wrap(
            spacing: AppSpacing.x2,
            children: [
              HangoutButton(
                label: context.l10n.crewsStart,
                size: HangoutButtonSize.sm,
                variant: HangoutButtonVariant.tonal,
                onPressed: onCreate,
              ),
              HangoutButton(
                label: context.l10n.crewsJoinWithCode,
                size: HangoutButtonSize.sm,
                variant: HangoutButtonVariant.secondary,
                onPressed: onJoin,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrewsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _CrewsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return HangoutListGroup(
      children: [
        HangoutListRow(
          leading: const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.textMuted,
          ),
          title: context.l10n.crewsLoadFailed,
          subtitle: context.l10n.errorCheckConnection,
          trailing: HangoutButton(
            label: context.l10n.crewsRetry,
            size: HangoutButtonSize.sm,
            variant: HangoutButtonVariant.ghost,
            onPressed: onRetry,
          ),
        ),
      ],
    );
  }
}

// ─── Join a crew ──────────────────────────────────────────────────────────────

class _JoinCrewSheet extends StatefulWidget {
  final GroupService service;

  const _JoinCrewSheet({required this.service});

  @override
  State<_JoinCrewSheet> createState() => _JoinCrewSheetState();
}

class _JoinCrewSheetState extends State<_JoinCrewSheet> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _code.text.trim().toUpperCase();
    if (code.length != 6 || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.service.joinByCode(code);
    if (!mounted) return;

    if (!result.success) {
      HapticFeedback.heavyImpact();
      setState(() {
        _loading = false;
        _error = result.type == JoinResultType.full
            ? context.l10n.joinFull(result.groupName ?? '')
            : context.l10n.joinNotFound;
      });
      return;
    }

    HapticFeedback.mediumImpact();
    final nav = Navigator.of(context);
    nav.pop();
    final group = await widget.service.getGroupDetails(result.groupId!);
    if (group == null) return;
    unawaited(
      nav.push(
        MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: HangoutSheet(
        title: context.l10n.joinTitle,
        subtitle: context.l10n.joinSubtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _code,
              autofocus: true,
              maxLength: 6,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              style: AppTextStyles.statNumber(28).copyWith(letterSpacing: 10),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'ABC123',
                hintStyle: AppTextStyles.statNumber(
                  28,
                ).copyWith(letterSpacing: 10, color: AppColors.sand300),
                errorText: _error,
              ),
              onChanged: (v) {
                if (_error != null) setState(() => _error = null);
                if (v.length == 6) _join();
              },
            ),
            const SizedBox(height: AppSpacing.x4),
            HangoutButton(
              label: context.l10n.joinButton,
              size: HangoutButtonSize.lg,
              block: true,
              loading: _loading,
              onPressed: _join,
            ),
          ],
        ),
      ),
    );
  }
}
