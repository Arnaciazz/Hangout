import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../services/group_service.dart';
import '../services/history_service.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../utils/dates.dart';
import '../widgets/dino_avatar.dart';
import '../widgets/hangout_card.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_logo.dart';
import '../widgets/hangout_motion.dart';
import 'group_detail_screen.dart';
import 'mode_lobby_screen.dart';
import 'place_swipe_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Switch the shell to the You / Memories tabs.
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenMemories;

  const HomeScreen({super.key, this.onOpenProfile, this.onOpenMemories});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _groupService = GroupService();
  final _historyService = HistoryService();

  ActiveHangout? _active;
  HangoutMemory? _lastTime;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _historyService.fetchActive(),
      ProfileService().fetchProfile(),
      _historyService
          .fetchMemories(limit: 1)
          .catchError((_) => <HangoutMemory>[]),
    ]);
    if (!mounted) return;
    final memories = results[2] as List<HangoutMemory>;
    setState(() {
      _active = results[0] as ActiveHangout?;
      _profile = results[1] as Map<String, dynamic>?;
      _lastTime = memories.isEmpty ? null : memories.first;
    });
  }

  void _openMode(String mode) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ModeLobbyScreen(mode: mode)),
    );
  }

  Future<void> _openActive(ActiveHangout a) async {
    try {
      if (a.groupId != null) {
        final group = await _groupService.getGroupDetails(a.groupId!);
        if (!mounted || group == null) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GroupDetailScreen(group: group),
        ));
      } else {
        final session = await SessionService().getSessionWithPlaces(a.sessionId);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlaceSwipeScreen(session: session, resume: true),
        ));
      }
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.homeOpenFailed)),
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return RefreshIndicator(
      onRefresh: _load,
      edgeOffset: 64,
      child: HomeView(
        now: DateTime.now(),
        nickname: _profile?['nickname'] as String? ??
            user?.userMetadata?['full_name'] as String?,
        avatarId: _profile?['avatar_id'] as int?,
        photoUrl: user?.userMetadata?['avatar_url'] as String?,
        active: _active != null && _showActive(_active!) ? _active : null,
        lastTime: _lastTime?.winner != null ? _lastTime : null,
        onEat: () => _openMode('hunger'),
        onExplore: () => _openMode('travel'),
        onOpenActive: _active == null ? null : () => _openActive(_active!),
        onOpenProfile: widget.onOpenProfile,
        onOpenMemories: widget.onOpenMemories,
      ),
    );
  }

  /// A solo session stuck in setup was abandoned before places loaded; there's
  /// nothing to go back to.
  bool _showActive(ActiveHangout a) =>
      a.groupId != null || a.status == 'swiping';
}

/// Pure presentation of Home — all state comes in as arguments, so it renders
/// with fixtures in tests exactly as it does in the app.
class HomeView extends StatelessWidget {
  final DateTime now;
  final String? nickname;
  final int? avatarId;
  final String? photoUrl;
  final ActiveHangout? active;
  final HangoutMemory? lastTime;
  final VoidCallback? onEat;
  final VoidCallback? onExplore;
  final VoidCallback? onOpenActive;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenMemories;

  const HomeView({
    super.key,
    required this.now,
    this.nickname,
    this.avatarId,
    this.photoUrl,
    this.active,
    this.lastTime,
    this.onEat,
    this.onExplore,
    this.onOpenActive,
    this.onOpenProfile,
    this.onOpenMemories,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = nickname ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            toolbarHeight: 60,
            titleSpacing: AppSpacing.gutter,
            title: const HangoutWordmark(height: 26),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.x3),
                child: Semantics(
                  button: true,
                  label: l10n.homeProfile,
                  child: Pressable(
                    onTap: onOpenProfile,
                    scale: 0.9,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: UserDinoAvatar(
                          avatarId: avatarId,
                          fallbackUrl: photoUrl,
                          fallbackInitial: name.isNotEmpty ? name[0] : '?',
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter, AppSpacing.x3, AppSpacing.gutter, 120),
            sliver: SliverList.list(
              children: [
                Text(
                  now.hour < 17 ? l10n.homeGreetingDay : l10n.homeGreetingNight,
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: AppSpacing.x5),
                Row(
                  children: [
                    Expanded(
                      child: HangoutButton(
                        label: l10n.homeEat,
                        iconLeft: Icons.restaurant_rounded,
                        size: HangoutButtonSize.lg,
                        variant: HangoutButtonVariant.secondary,
                        block: true,
                        onPressed: onEat,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: HangoutButton(
                        label: l10n.homeExplore,
                        iconLeft: Icons.explore_rounded,
                        size: HangoutButtonSize.lg,
                        variant: HangoutButtonVariant.secondary,
                        block: true,
                        onPressed: onExplore,
                      ),
                    ),
                  ],
                ),
                if (active != null) ...[
                  const SizedBox(height: AppSpacing.x8),
                  _InProgressCard(hangout: active!, onOpen: onOpenActive),
                ],
                if (lastTime != null) ...[
                  const SizedBox(height: AppSpacing.x8),
                  SectionHeader(
                    title: l10n.homeLastTime,
                    action: l10n.homeAllMemories,
                    onAction: onOpenMemories,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  _LastTimeCard(memory: lastTime!, onTap: onOpenMemories),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

}

// ─── In progress ──────────────────────────────────────────────────────────────

class _InProgressCard extends StatelessWidget {
  final ActiveHangout hangout;
  final VoidCallback? onOpen;

  const _InProgressCard({required this.hangout, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final swiping = hangout.status == 'swiping';
    final food = hangout.mode == 'hunger';
    final who = hangout.groupName ?? l10n.memoryJustYou;
    final state = swiping
        ? (food ? l10n.homeSwipingFood : l10n.homeSwipingPlaces)
        : (food ? l10n.homePinsFood : l10n.homePinsPlaces);

    return Pressable(
      onTap: onOpen,
      scale: 0.98,
      child: Container(
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
                    who,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
            HangoutButton(
              label: swiping ? l10n.crewSessionSwipe : l10n.crewSessionOpen,
              size: HangoutButtonSize.sm,
              variant: HangoutButtonVariant.tonal,
              onPressed: onOpen,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Last time ────────────────────────────────────────────────────────────────

/// The most recent winner, image-forward — the design system's place card at
/// full width.
class _LastTimeCard extends StatelessWidget {
  final HangoutMemory memory;
  final VoidCallback? onTap;

  const _LastTimeCard({required this.memory, this.onTap});

  @override
  Widget build(BuildContext context) {
    final place = memory.winner!;
    final total = memory.yesVotes + memory.noVotes;

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
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HangoutPhoto(url: place.mainPhotoUrl),
                  if (place.rating != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: HangoutBadge.rating(place.rating!),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      memory.groupName ?? context.l10n.memoryJustYou,
                      friendlyDate(context.l10n, memory.date),
                      if (total > 0)
                        context.l10n.resultsVotes(memory.yesVotes, total),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
