import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../models/group.dart';
import '../services/bill_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../utils/links.dart';
import '../utils/money.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_card.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_list.dart';
import '../widgets/hangout_motion.dart';
import 'bill_screen.dart';
import 'place_detail_screen.dart';
import 'session_setup_screen.dart';

/// Where a session landed. A crew gets its winner (and the bill); a solo
/// swiper gets every place they liked.
///
/// Reads saved results; it never re-tallies. With [celebrate] it plays the
/// reveal: the winner springs in under a short burst of confetti.
class ResultsScreen extends StatefulWidget {
  final SessionModel session;
  final Group? group;
  final SessionService? service;
  final List<PlaceResult>? precomputedResults;
  final bool celebrate;

  const ResultsScreen({
    super.key,
    required this.session,
    required this.group,
    this.service,
    this.precomputedResults,
    this.celebrate = false,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final SessionService _service = widget.service ?? SessionService();
  Stream<Bill?>? _bill;
  ConfettiController? _confetti;

  List<PlaceResult>? _results;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _results = widget.precomputedResults;
    if (_results == null) _load();
    if (widget.group != null) {
      _bill = BillService().watchBill(widget.session.id);
    }
    if (widget.celebrate) {
      _confetti = ConfettiController(
        duration: const Duration(milliseconds: 600),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
        HapticFeedback.heavyImpact();
        if (_results?.firstOrNull?.isWinner ?? false) _confetti!.play();
      });
    }
  }

  @override
  void dispose() {
    _confetti?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final results = await _service.getResults(widget.session.id);
      if (!mounted) return;
      setState(() => _results = results);
      if (widget.celebrate && (results.firstOrNull?.isWinner ?? false)) {
        _confetti?.play();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _openPlace(PlaceResult r) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => PlaceDetailScreen(
              place: r.place,
              mode: widget.session.mode,
              voteLine: widget.group == null ? null : voteLine(context, r),
            ),
      ),
    );
  }

  void _openBill() {
    final winner = _results?.firstOrNull;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => BillScreen(
              sessionId: widget.session.id,
              group: widget.group!,
              placeName:
                  winner != null && winner.isWinner ? winner.place.name : null,
            ),
      ),
    );
  }

  void _startAgain() {
    final nav = Navigator.of(context);
    nav.popUntil((r) => r.isFirst);
    nav.push(
      MaterialPageRoute(
        builder:
            (_) => SessionSetupScreen(
              group: widget.group,
              mode: widget.session.mode,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final results = _results;
    final winner =
        results != null && results.isNotEmpty && results.first.isWinner
            ? results.first
            : null;

    final Widget body;
    if (_failed) {
      body = _Failed(onRetry: _load);
    } else if (results == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = ResultsView(
        results: results,
        mode: widget.session.mode,
        group: widget.group,
        myId: Supabase.instance.client.auth.currentUser?.id,
        bill: _bill,
        celebrate: widget.celebrate,
        onOpenPlace: _openPlace,
        onOpenBill: _openBill,
        onStartAgain: _startAgain,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: HangoutBackButton(
          icon: Icons.close_rounded,
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        actions: [
          if (winner != null)
            HangoutIconButton(
              icon: Icons.share_rounded,
              tooltip: l10n.actionShare,
              onPressed:
                  () => openLink(
                    context,
                    whatsAppShareUri(
                      l10n.resultsShareMessage(
                        winner.place.name,
                        winner.place.mapsUri.toString(),
                      ),
                    ),
                  ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: body),
          if (_confetti != null)
            Align(
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: _confetti!,
                  blastDirectionality: BlastDirectionality.explosive,
                  blastDirection: math.pi / 2,
                  emissionFrequency: 0.08,
                  numberOfParticles: 18,
                  maxBlastForce: 24,
                  minBlastForce: 8,
                  gravity: 0.25,
                  minimumSize: const Size(8, 5),
                  maximumSize: const Size(14, 8),
                  colors: const [
                    AppColors.brand,
                    AppColors.honey500,
                    AppColors.paprika200,
                    AppColors.honey300,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "4 of 5 said yes".
String voteLine(BuildContext context, PlaceResult r) {
  final total = r.yesVotes + r.noVotes;
  return total == 0
      ? context.l10n.resultsNoVotes
      : context.l10n.resultsVotes(r.yesVotes, total);
}

/// Pure presentation of a session's results, so it renders in tests with
/// fixtures and no backend.
class ResultsView extends StatelessWidget {
  final List<PlaceResult> results;
  final String mode;
  final Group? group;
  final String? myId;
  final Stream<Bill?>? bill;
  final bool celebrate;
  final ValueChanged<PlaceResult> onOpenPlace;
  final VoidCallback? onOpenBill;
  final VoidCallback? onStartAgain;

  const ResultsView({
    super.key,
    required this.results,
    required this.mode,
    required this.group,
    required this.onOpenPlace,
    this.myId,
    this.bill,
    this.celebrate = false,
    this.onOpenBill,
    this.onStartAgain,
  });

  bool get _isFood => mode == 'hunger';

  @override
  Widget build(BuildContext context) {
    return group == null ? _solo(context) : _crew(context);
  }

  EdgeInsets _padding(BuildContext context) => EdgeInsets.fromLTRB(
    AppSpacing.gutter,
    AppSpacing.x2,
    AppSpacing.gutter,
    AppSpacing.x10 + MediaQuery.of(context).padding.bottom,
  );

  // ─── Crew ──────────────────────────────────────────────────────────────────

  Widget _crew(BuildContext context) {
    final l10n = context.l10n;
    final shown = results.take(10).toList();
    final winner =
        shown.isNotEmpty && shown.first.isWinner ? shown.first : null;
    final rest = winner == null ? shown : shown.sublist(1);

    return ListView(
      padding: _padding(context),
      children: [
        Text(
          winner != null ? l10n.resultsDecidedTitle : l10n.resultsNoWinnerTitle,
          style: AppTextStyles.h1,
        ),
        const SizedBox(height: 4),
        Text(
          winner != null
              ? l10n.resultsCrewPicked(group!.name)
              : l10n.resultsNoYes,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.x6),
        if (winner != null)
          _Entrance(
            enabled: celebrate,
            child: _WinnerCard(
              result: winner,
              isFood: _isFood,
              onOpen: () => onOpenPlace(winner),
            ),
          )
        else if (onStartAgain != null)
          HangoutButton(
            label: l10n.resultsStartAgain,
            size: HangoutButtonSize.lg,
            block: true,
            onPressed: onStartAgain,
          ),
        if (winner != null && onOpenBill != null) ...[
          const SizedBox(height: AppSpacing.x4),
          _BillTile(bill: bill, myId: myId, onTap: onOpenBill!),
        ],
        if (rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x8),
          SectionHeader(
            title:
                winner != null ? l10n.resultsRunnersUp : l10n.resultsHowItWent,
          ),
          const SizedBox(height: AppSpacing.x2),
          HangoutListGroup(
            children: [
              for (final r in rest)
                HangoutListRow(
                  leading: _Thumb(url: r.place.mainPhotoUrl, isFood: _isFood),
                  title: r.place.name,
                  subtitle: l10n.resultsVoteShort(r.yesVotes, r.noVotes),
                  trailing: Text(
                    '${r.votePercent.round()}%',
                    style: AppTextStyles.smallStrong,
                  ),
                  onTap: () => onOpenPlace(r),
                ),
            ],
          ),
        ],
      ],
    );
  }

  // ─── Solo ──────────────────────────────────────────────────────────────────

  Widget _solo(BuildContext context) {
    final l10n = context.l10n;
    final liked = [
      for (final r in results)
        if (r.yesVotes > 0) r,
    ];
    final passed = [
      for (final r in results)
        if (r.yesVotes == 0) r,
    ];

    return ListView(
      padding: _padding(context),
      children: [
        Text(
          liked.isEmpty ? l10n.soloNothingTitle : l10n.soloPicksTitle,
          style: AppTextStyles.h1,
        ),
        const SizedBox(height: 4),
        Text(
          liked.isEmpty
              ? l10n.soloNothingBody(results.length)
              : l10n.soloLikedCount(liked.length, results.length),
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.x6),
        for (final r in liked) ...[
          _PickCard(result: r, isFood: _isFood, onOpen: () => onOpenPlace(r)),
          const SizedBox(height: AppSpacing.x4),
        ],
        if (onStartAgain != null)
          HangoutButton(
            label: l10n.soloSwipeAgain,
            size: HangoutButtonSize.lg,
            block: true,
            variant:
                liked.isEmpty
                    ? HangoutButtonVariant.primary
                    : HangoutButtonVariant.secondary,
            onPressed: onStartAgain,
          ),
        if (passed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x8),
          SectionHeader(title: l10n.soloPassedTitle),
          const SizedBox(height: AppSpacing.x2),
          HangoutListGroup(
            children: [
              for (final r in passed)
                HangoutListRow(
                  leading: _Thumb(url: r.place.mainPhotoUrl, isFood: _isFood),
                  title: r.place.name,
                  subtitle: r.place.cuisineType,
                  showChevron: true,
                  onTap: () => onOpenPlace(r),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The reveal: the winner springs up into place once. Off when the person
/// has asked for less motion, and on every later visit.
class _Entrance extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const _Entrance({required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!enabled || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 560),
      curve: AppMotion.spring,
      child: child,
      builder:
          (context, v, child) => Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 24 * (1 - v)),
              child: Transform.scale(scale: 0.94 + 0.06 * v, child: child),
            ),
          ),
    );
  }
}

/// The payoff. The winner gets the full image-forward treatment and the one
/// primary action on the screen.
class _WinnerCard extends StatelessWidget {
  final PlaceResult result;
  final bool isFood;
  final VoidCallback onOpen;

  const _WinnerCard({
    required this.result,
    required this.isFood,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final place = result.place;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlAll,
        boxShadow: AppShadows.lg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: onOpen,
            scale: 0.98,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      HangoutPhoto(
                        url: place.mainPhotoUrl,
                        fallbackIcon:
                            isFood
                                ? Icons.restaurant_rounded
                                : Icons.explore_rounded,
                      ),
                      PhotoRating(place: place),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h2,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      PlaceFacts(place: place, showRating: false),
                      const SizedBox(height: AppSpacing.x3),
                      Text(
                        voteLine(context, result),
                        style: AppTextStyles.smallStrong.copyWith(
                          color: AppColors.avocado700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: PlaceActions(place: place, isFood: isFood),
          ),
        ],
      ),
    );
  }
}

/// One place a solo swiper liked, with its two quickest ways out.
class _PickCard extends StatelessWidget {
  final PlaceResult result;
  final bool isFood;
  final VoidCallback onOpen;

  const _PickCard({
    required this.result,
    required this.isFood,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final place = result.place;

    return Pressable(
      onTap: onOpen,
      scale: 0.98,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.xlAll,
          boxShadow: AppShadows.md,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 0, 0),
                  child: ClipRRect(
                    borderRadius: AppRadius.mdAll,
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: HangoutPhoto(
                        url: place.mainPhotoUrl,
                        fallbackIcon:
                            isFood
                                ? Icons.restaurant_rounded
                                : Icons.explore_rounded,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title,
                        ),
                        if (place.address != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            place.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.x2),
                        PlaceFacts(place: place),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: PlaceActions(place: place, isFood: isFood, compact: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the money stands, one tap from settling it.
class _BillTile extends StatelessWidget {
  final Stream<Bill?>? bill;
  final String? myId;
  final VoidCallback onTap;

  const _BillTile({
    required this.bill,
    required this.myId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Bill?>(
      stream: bill,
      builder: (context, snap) => _row(context, snap.data),
    );
  }

  Widget _row(BuildContext context, Bill? b) {
    final l10n = context.l10n;
    final mine = b == null || myId == null ? null : b.shareOf(myId!);
    final iOwe = b != null && mine != null && !mine.paid && b.payerId != myId;

    final String title;
    final String subtitle;
    if (b == null) {
      title = l10n.billTileTitle;
      subtitle = l10n.billTileEmpty;
    } else {
      title = l10n.billTileTitleWithTotal(formatRupees(b.totalPaise));
      subtitle =
          iOwe
              ? l10n.billTileYouOwe(b.payerName, formatRupees(mine.amountPaise))
              : b.settled
              ? l10n.billTileSettled
              : l10n.billTileProgress(
                b.payerName,
                b.paidCount,
                b.shares.length,
              );
    }

    return HangoutListGroup(
      children: [
        HangoutListRow(
          leading: const SizedBox(
            width: 32,
            child: Icon(
              Icons.receipt_long_outlined,
              color: AppColors.textMuted,
            ),
          ),
          title: title,
          subtitle: subtitle,
          subtitleColor: iOwe ? AppColors.paprika700 : null,
          trailing:
              b != null && b.settled
                  ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accentFresh,
                    size: 20,
                  )
                  : null,
          showChevron: true,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  final String url;
  final bool isFood;

  const _Thumb({required this.url, required this.isFood});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.smAll,
      child: SizedBox(
        width: 44,
        height: 44,
        child: HangoutPhoto(
          url: url,
          fallbackIcon:
              isFood ? Icons.restaurant_rounded : Icons.explore_rounded,
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  final VoidCallback onRetry;

  const _Failed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.resultsLoadFailed, style: AppTextStyles.bodyStrong),
          const SizedBox(height: 4),
          Text(l10n.errorCheckConnection, style: AppTextStyles.small),
          const SizedBox(height: AppSpacing.x3),
          HangoutButton(
            label: l10n.actionTryAgain,
            size: HangoutButtonSize.sm,
            variant: HangoutButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
