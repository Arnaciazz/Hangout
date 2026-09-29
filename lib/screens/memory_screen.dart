import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_card.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_list.dart';
import '../widgets/hangout_motion.dart';

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
            body = MemoriesView(memories: snap.data!, onOpen: _openInMaps);
          }
          return RefreshIndicator(onRefresh: _reload, child: body);
        },
      ),
    );
  }

  Future<void> _openInMaps(HangoutMemory m) async {
    final place = m.winner;
    if (place == null) return;
    final uri = Uri.parse(place.googleMapsUri ??
        'https://www.google.com/maps/search/?api=1&query='
            '${Uri.encodeComponent('${place.name} ${place.address ?? ''}')}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open Maps.")),
      );
    }
  }
}

/// Pure presentation of the memories list — no data loading, so it can be
/// rendered in tests with fixtures.
class MemoriesView extends StatelessWidget {
  final List<HangoutMemory> memories;
  final ValueChanged<HangoutMemory>? onOpen;

  const MemoriesView({super.key, required this.memories, this.onOpen});

  @override
  Widget build(BuildContext context) {
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
        Text('Memories', style: AppTextStyles.h1),
        const SizedBox(height: 2),
        Text(
          memories.isEmpty
              ? 'Where your crews ended up'
              : '${memories.length} ${memories.length == 1 ? 'hangout' : 'hangouts'} so far',
          style: AppTextStyles.small,
        ),
        const SizedBox(height: AppSpacing.x5),
        if (latest == null)
          const _EmptyState()
        else ...[
          _LatestCard(memory: latest, onTap: () => onOpen?.call(latest)),
          if (earlier.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x8),
            const SectionHeader(title: 'Earlier'),
            const SizedBox(height: AppSpacing.x2),
            HangoutListGroup(
              children: [
                for (final m in earlier)
                  HangoutListRow(
                    leading: _Thumb(memory: m),
                    title: m.winner?.name ?? 'No winner',
                    subtitle: _meta(m),
                    trailing: _Votes(memory: m),
                    onTap: m.winner == null ? null : () => onOpen?.call(m),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  static String _meta(HangoutMemory m) =>
      '${m.groupName ?? 'Just you'} · ${friendlyDate(m.date)}';
}

class _LatestCard extends StatelessWidget {
  final HangoutMemory memory;
  final VoidCallback onTap;

  const _LatestCard({required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final place = memory.winner;

    return Pressable(
      onTap: place == null ? null : onTap,
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place?.name ?? 'No winner this time',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    MemoriesView._meta(memory),
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
    final total = memory.yesVotes + memory.noVotes;
    if (memory.winner == null || total == 0) {
      return Text(long ? 'Nobody said yes to anything' : '—',
          style: AppTextStyles.caption);
    }
    final label = long
        ? '${memory.yesVotes} of $total said yes'
        : '${memory.yesVotes}/$total';
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
          Text('Nothing here yet', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(
            'When a crew lands on a winner, it’s saved here — where '
            'you went, who came, and how close the vote was.',
            style: AppTextStyles.small,
          ),
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
        Text('Memories', style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.x5 + 22),
        Semantics(
          label: 'Loading memories',
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
        Text('Memories', style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.x5),
        Text("Couldn't load your hangouts.", style: AppTextStyles.bodyStrong),
        const SizedBox(height: 4),
        Text('Check your connection and try again.', style: AppTextStyles.small),
        const SizedBox(height: AppSpacing.x3),
        Align(
          alignment: Alignment.centerLeft,
          child: HangoutButton(
            label: 'Try again',
            size: HangoutButtonSize.sm,
            variant: HangoutButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ),
      ],
    );
  }
}
