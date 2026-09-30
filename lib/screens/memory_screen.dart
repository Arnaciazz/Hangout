import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/history_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../utils/dates.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_card.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_list.dart';
import '../widgets/hangout_motion.dart';
import 'results_screen.dart';

/// Every hangout that landed on a winner, newest first.
class MemoryScreen extends StatefulWidget {
  /// Bumped by the shell when this tab is re-entered, so a hangout that just
  /// finished shows up.
  final int refreshToken;

  const MemoryScreen({super.key, this.refreshToken = 0});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final _history = HistoryService();
  late Future<List<HangoutMemory>> _future = _history.fetchMemories();

  /// Marked "Didn't go" this visit; hidden straight away, before the server
  /// confirms, and shown again on Undo.
  final _hidden = <String>{};

  @override
  void didUpdateWidget(covariant MemoryScreen old) {
    super.didUpdateWidget(old);
    if (old.refreshToken != widget.refreshToken) _reload();
  }

  Future<void> _reload() async {
    final next = _history.fetchMemories();
    setState(() => _future = next);
    await next.catchError((_) => <HangoutMemory>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<HangoutMemory>>(
        future: _future,
        builder: (context, snap) {
          final Widget body;
          if (snap.hasError) {
            body = _ErrorState(onRetry: _reload);
          } else if (!snap.hasData) {
            body = const _LoadingState();
          } else {
            body = MemoriesView(
              memories: [
                for (final m in snap.data!)
                  if (!_hidden.contains(m.sessionId)) m,
              ],
              onOpen: _open,
              onDidntGo: _didntGo,
            );
          }
          return RefreshIndicator(onRefresh: _reload, child: body);
        },
      ),
    );
  }

  /// The hangout's full results: winner, runners-up, and the bill.
  Future<void> _open(HangoutMemory m) async {
    Group? group;
    if (m.groupId != null) {
      try {
        group = await GroupService().getGroupDetails(m.groupId!);
      } catch (_) {}
      if (!mounted) return;
      if (group == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.memoryOpenFailed)),
        );
        return;
      }
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultsScreen(
        session: SessionModel(
          id: m.sessionId,
          groupId: m.groupId,
          userId: '',
          mode: m.mode,
          type: group == null ? 'solo' : 'group',
          status: 'revealed',
        ),
        group: group,
      ),
    ));
  }

  /// "Didn't go": off this person's memories (and counts), with Undo.
  Future<void> _didntGo(HangoutMemory m) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _hidden.add(m.sessionId));
    try {
      await _history.dismiss(m.sessionId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hidden.remove(m.sessionId));
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.memoryRemoved),
        action: SnackBarAction(
          label: l10n.actionUndo,
          onPressed: () async {
            try {
              await _history.undoDismiss(m.sessionId);
            } catch (_) {
              return;
            }
            if (mounted) setState(() => _hidden.remove(m.sessionId));
          },
        ),
      ));
  }
}

/// Pure presentation of the memories list — no data loading, so it can be
/// rendered in tests with fixtures.
class MemoriesView extends StatelessWidget {
  final List<HangoutMemory> memories;
  final ValueChanged<HangoutMemory>? onOpen;
  final ValueChanged<HangoutMemory>? onDidntGo;

  const MemoriesView({
    super.key,
    required this.memories,
    this.onOpen,
    this.onDidntGo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final latest = memories.isEmpty ? null : memories.first;
    final earlier = memories.length > 1 ? memories.sublist(1) : const <HangoutMemory>[];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        MediaQuery.of(context).padding.top + AppSpacing.x5,
        AppSpacing.gutter,
        120,
      ),
      children: [
        Text(l10n.memoriesTitle, style: AppTextStyles.h1),
        const SizedBox(height: 2),
        Text(
          memories.isEmpty
              ? l10n.memoriesSubtitleEmpty
              : l10n.memoriesCount(memories.length),
          style: AppTextStyles.small,
        ),
        const SizedBox(height: AppSpacing.x5),
        if (latest == null)
          const _EmptyState()
        else ...[
          _LatestCard(
            memory: latest,
            onTap: () => onOpen?.call(latest),
            onDidntGo:
                onDidntGo == null ? null : () => onDidntGo!.call(latest),
          ),
          if (earlier.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x8),
            SectionHeader(title: l10n.memoriesEarlier),
            const SizedBox(height: AppSpacing.x2),
            HangoutListGroup(
              children: [
                for (final m in earlier)
                  HangoutListRow(
                    leading: _Thumb(memory: m),
                    title: m.winner?.name ?? l10n.memoryNoWinner,
                    subtitle: meta(context, m),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Votes(memory: m),
                        if (onDidntGo != null)
                          _MemoryMenu(onDidntGo: () => onDidntGo!.call(m)),
                      ],
                    ),
                    onTap: () => onOpen?.call(m),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  static String meta(BuildContext context, HangoutMemory m) =>
      context.l10n.memoryMeta(
        m.groupName ?? context.l10n.memoryJustYou,
        friendlyDate(context.l10n, m.date),
      );
}

/// The "Didn't go" option: hides a hangout from this person's memories only.
class _MemoryMenu extends StatelessWidget {
  final VoidCallback onDidntGo;
  final bool onPhoto;

  const _MemoryMenu({required this.onDidntGo, this.onPhoto = false});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.actionMore,
      onSelected: (_) => onDidntGo(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'didnt-go',
          child: Row(
            children: [
              const Icon(Icons.remove_circle_outline_rounded,
                  size: 20, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.x3),
              Text(l10n.memoryDidntGo, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: onPhoto
              ? Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInverse.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert_rounded,
                      color: Colors.white, size: 20),
                )
              : const Icon(Icons.more_vert_rounded,
                  color: AppColors.textMuted, size: 20),
        ),
      ),
    );
  }
}

class _LatestCard extends StatelessWidget {
  final HangoutMemory memory;
  final VoidCallback onTap;
  final VoidCallback? onDidntGo;

  const _LatestCard({
    required this.memory,
    required this.onTap,
    this.onDidntGo,
  });

  @override
  Widget build(BuildContext context) {
    final place = memory.winner;

    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.xlAll,
          boxShadow: AppShadows.lg,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HangoutPhoto(
                    url: place?.mainPhotoUrl,
                    fallbackIcon: memory.mode == 'hunger'
                        ? Icons.restaurant_rounded
                        : Icons.explore_rounded,
                  ),
                  if (place?.rating != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: HangoutBadge.rating(place!.rating!),
                    ),
                  if (onDidntGo != null)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: _MemoryMenu(onDidntGo: onDidntGo!, onPhoto: true),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place?.name ?? context.l10n.memoryNoWinnerLong,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    MemoriesView.meta(context, memory),
                    style: AppTextStyles.small,
                  ),
                  const SizedBox(height: 12),
                  _Votes(memory: memory, long: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final HangoutMemory memory;

  const _Thumb({required this.memory});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: SizedBox(
        width: 52,
        height: 52,
        child: HangoutPhoto(
          url: memory.winner?.mainPhotoUrl,
          fallbackIcon: memory.mode == 'hunger'
              ? Icons.restaurant_rounded
              : Icons.explore_rounded,
        ),
      ),
    );
  }
}

/// "4 of 5 said yes". The share of the crew that wanted the winner is the one
/// number that says how the night went.
class _Votes extends StatelessWidget {
  final HangoutMemory memory;
  final bool long;

  const _Votes({required this.memory, this.long = false});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = memory.yesVotes + memory.noVotes;
    if (memory.winner == null || total == 0) {
      return Text(long ? l10n.memoryNobodyYes : '—',
          style: AppTextStyles.caption);
    }
    final label = long
        ? l10n.resultsVotes(memory.yesVotes, total)
        : l10n.memoryVotesShort(memory.yesVotes, total);
    return Text(
      label,
      style: AppTextStyles.captionStrong.copyWith(color: AppColors.avocado700),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
          Text(context.l10n.memoriesEmptyTitle, style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(context.l10n.memoriesEmptyBody, style: AppTextStyles.small),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        MediaQuery.of(context).padding.top + AppSpacing.x5,
        AppSpacing.gutter,
        120,
      ),
      children: [
        Text(context.l10n.memoriesTitle, style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.x5 + 22),
        Semantics(
          label: context.l10n.memoriesLoading,
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: AppRadius.xlAll,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        MediaQuery.of(context).padding.top + AppSpacing.x5,
        AppSpacing.gutter,
        120,
      ),
      children: [
        Text(context.l10n.memoriesTitle, style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.x5),
        Text(context.l10n.memoriesLoadFailed, style: AppTextStyles.bodyStrong),
        const SizedBox(height: 4),
        Text(context.l10n.errorCheckConnection, style: AppTextStyles.small),
        const SizedBox(height: AppSpacing.x3),
        Align(
          alignment: Alignment.centerLeft,
          child: HangoutButton(
            label: context.l10n.actionTryAgain,
            size: HangoutButtonSize.sm,
            variant: HangoutButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ),
      ],
    );
  }
}
