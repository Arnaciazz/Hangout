import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/group.dart';
import '../models/place.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_avatar.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_card.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_list.dart';

/// The swipe deck.
///
/// Photography is the whole point here, so the stage sits on warm ink
/// (`sand-900`) and every label over an image rides on a protection gradient.
/// Cards drag with rotation, stamp I'm in / Nope progressively as you pull, and
/// fly off on release rather than snapping.
class PlaceSwipeScreen extends StatefulWidget {
  final SessionModel session;
  final Group? group;

  /// Injected in tests; created on first use otherwise.
  final SessionService? service;

  const PlaceSwipeScreen({
    super.key,
    required this.session,
    this.group,
    this.service,
  });

  @override
  State<PlaceSwipeScreen> createState() => _PlaceSwipeScreenState();
}

class _PlaceSwipeScreenState extends State<PlaceSwipeScreen>
    with TickerProviderStateMixin {
  late final SessionService _service = widget.service ?? SessionService();

  int _currentIndex = 0;
  bool _swiping = false;

  final Map<int, int> _photoIndex = {};

  StreamSubscription<({int membersFinished, int totalMembers})>? _progressSub;
  ({int membersFinished, int totalMembers})? _groupProgress;

  Offset _dragOffset = Offset.zero;
  bool _dragging = false;

  /// Drives the fly-off when a card is committed.
  late final AnimationController _flyCtrl = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  Animation<Offset>? _flyAnim;

  final _detailsKey = GlobalKey();
  final _scrollController = ScrollController();

  List<Place> get _places => widget.session.places;
  Place? get _current =>
      _currentIndex < _places.length ? _places[_currentIndex] : null;
  Place? get _next =>
      _currentIndex + 1 < _places.length ? _places[_currentIndex + 1] : null;

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    if (g != null) {
      _progressSub = _service
          .watchGroupProgress(widget.session.id, g.id)
          .listen((p) {
            if (mounted) setState(() => _groupProgress = p);
          });
    }
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _flyCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Swipe ─────────────────────────────────────────────────────────────────

  /// -1 … 1 — how committed the current drag is. Drives the stamps and the
  /// tint on the action buttons.
  double get _dragProgress {
    final w = MediaQuery.of(context).size.width;
    return (_dragOffset.dx / (w * 0.35)).clamp(-1.0, 1.0);
  }

  Future<void> _swipe(String direction) async {
    if (_swiping || _current == null || _current!.id == null) return;

    setState(() => _swiping = true);
    HapticFeedback.mediumImpact();

    // Fly the card off in the direction of travel before advancing.
    final width = MediaQuery.of(context).size.width;
    final target = Offset(
      direction == 'yes' ? width * 1.4 : -width * 1.4,
      _dragOffset.dy - 40,
    );
    _flyAnim = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(parent: _flyCtrl, curve: AppMotion.easeOut));
    unawaited(() async {
      try {
        await _service.recordSwipe(
          sessionId: widget.session.id,
          placeId: _current!.id!,
          direction: direction,
        );
      } catch (_) {
        // Fire-and-forget; the service retries in the background.
      }
    }());

    await _flyCtrl.forward(from: 0);
    if (!mounted) return;

    setState(() {
      _currentIndex++;
      _dragOffset = Offset.zero;
      _flyAnim = null;
      _swiping = false;
    });
    _flyCtrl.value = 0;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);

    if (_currentIndex >= _places.length) _showDone();
  }

  void _showDone() {
    if (widget.group != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => _WaitingScreen(
                session: widget.session,
                group: widget.group!,
                service: _service,
              ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => ResultsScreen(
                session: widget.session,
                group: widget.group,
                service: widget.service,
              ),
        ),
      );
    }
  }

  // Horizontal-only drag, so the details below the hero still scroll freely.
  void _onDragStart(DragStartDetails d) {
    if (_swiping) return;
    setState(() => _dragging = true);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_dragging || _swiping) return;
    setState(() => _dragOffset += Offset(d.delta.dx, d.delta.dx.abs() * 0.06));
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_dragging) return;
    setState(() => _dragging = false);

    final threshold = MediaQuery.of(context).size.width * 0.3;
    final flung = d.velocity.pixelsPerSecond.dx.abs() > 700;

    if (_dragOffset.dx > threshold || (flung && _dragOffset.dx > 0)) {
      _swipe('yes');
    } else if (_dragOffset.dx < -threshold || (flung && _dragOffset.dx < 0)) {
      _swipe('no');
    } else {
      setState(() => _dragOffset = Offset.zero);
    }
  }

  void _scrollToDetails() {
    final ctx = _detailsKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: AppMotion.slow,
      curve: AppMotion.easeOut,
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_places.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surfaceInverse,
        body: Center(
          child: Text(
            'Nothing to swipe on yet.',
            style: AppTextStyles.body.copyWith(color: AppColors.textOnDark),
          ),
        ),
      );
    }

    if (_currentIndex >= _places.length) {
      return const Scaffold(backgroundColor: AppColors.surfaceInverse);
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.surfaceInverse,
      body: Stack(
        children: [
          // The next card peeks through behind the top one, so the deck reads
          // as a deck.
          if (_next != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Transform.scale(
                  scale: 0.94 + 0.06 * _dragProgress.abs(),
                  child: Opacity(
                    opacity: 0.35 + 0.35 * _dragProgress.abs(),
                    child: _PeekCard(place: _next!),
                  ),
                ),
              ),
            ),

          GestureDetector(
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: AnimatedBuilder(
              animation: _flyCtrl,
              builder: (context, child) {
                final offset = _flyAnim?.value ?? _dragOffset;
                return Transform(
                  alignment: Alignment.center,
                  transform:
                      Matrix4.identity()
                        ..translateByDouble(offset.dx, offset.dy, 0, 1)
                        ..rotateZ(offset.dx / size.width * 0.22),
                  child: child,
                );
              },
              child: _buildCard(_places[_currentIndex]),
            ),
          ),

          _buildProgressBar(),
          _buildStamps(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.x4,
                top: AppSpacing.x2,
              ),
              child: HangoutIconButton(
                icon: Icons.close_rounded,
                variant: HangoutIconButtonVariant.glass,
                tooltip: 'Close',
                size: 40,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActions(),
          ),

          if (widget.group != null && _groupProgress != null)
            _buildGroupProgressStrip(_groupProgress!),
        ],
      ),
    );
  }

  /// "I'm in" / "Nope" stamps that grow in as the drag commits.
  Widget _buildStamps() {
    final p = _dragProgress;
    if (p.abs() < 0.02) return const SizedBox.shrink();

    final isYes = p > 0;
    final strength = p.abs().clamp(0.0, 1.0);

    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          child: Align(
            alignment: isYes ? Alignment.topLeft : Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 90, 24, 0),
              child: Opacity(
                opacity: strength,
                child: Transform.rotate(
                  angle: (isYes ? -0.18 : 0.18),
                  child: Transform.scale(
                    scale: 0.8 + 0.2 * strength,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: (isYes
                                ? AppColors.accentFresh
                                : AppColors.danger)
                            .withValues(alpha: 0.16),
                        borderRadius: AppRadius.mdAll,
                        border: Border.all(
                          color:
                              isYes ? AppColors.accentFresh : AppColors.danger,
                          width: 3,
                        ),
                      ),
                      child: Text(
                        isYes ? "I'm in" : 'Nope',
                        style: AppTextStyles.statNumber(26).copyWith(
                          color:
                              isYes
                                  ? AppColors.avocado300
                                  : AppColors.paprika300,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final p = _dragProgress;

    return Container(
      padding: EdgeInsets.fromLTRB(
        32,
        AppSpacing.x4,
        32,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bg.withValues(alpha: 0),
            AppColors.bg,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Transform.scale(
            scale: 1 + (p < 0 ? p.abs() * 0.18 : 0),
            child: HangoutIconButton(
              icon: Icons.close_rounded,
              size: 58,
              tooltip: 'Pass',
              iconColor: AppColors.danger,
              variant: HangoutIconButtonVariant.surface,
              onPressed: _swiping ? null : () => _swipe('no'),
            ),
          ),
          Transform.scale(
            scale: 1 + (p > 0 ? p * 0.18 : 0),
            child: HangoutIconButton(
              icon: Icons.favorite_rounded,
              size: 72,
              tooltip: "I'm in",
              variant: HangoutIconButtonVariant.fresh,
              onPressed: _swiping ? null : () => _swipe('yes'),
            ),
          ),
          HangoutIconButton(
            icon: Icons.info_outline_rounded,
            size: 58,
            tooltip: 'Details',
            variant: HangoutIconButtonVariant.surface,
            iconColor: AppColors.textMuted,
            onPressed: _scrollToDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            72,
            AppSpacing.x5,
            AppSpacing.x5,
            0,
          ),
          child: Row(
            children: List.generate(_places.length, (i) {
              return Expanded(
                child: AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.easeOut,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color:
                        i < _currentIndex
                            ? AppColors.brand
                            : i == _currentIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupProgressStrip(
    ({int membersFinished, int totalMembers}) progress,
  ) {
    final done = progress.membersFinished;
    final total = progress.totalMembers;
    final allDone = done >= total;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 54,
      left: AppSpacing.gutter,
      right: AppSpacing.gutter,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x2,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: AppRadius.pillAll,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                allDone ? Icons.check_circle_rounded : Icons.people_alt_rounded,
                color: allDone ? AppColors.avocado300 : Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  allDone ? "Everyone's voted" : '$done of $total friends done',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionStrong.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Card ──────────────────────────────────────────────────────────────────

  Widget _buildCard(Place place) {
    final bottomBarHeight = MediaQuery.of(context).padding.bottom + 116.0;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHero(place)),
        SliverToBoxAdapter(child: _buildDetails(place)),
        SliverFillRemaining(
          hasScrollBody: false,
          child: ColoredBox(
            color: AppColors.bg,
            child: SizedBox(height: bottomBarHeight),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(Place place) {
    final size = MediaQuery.of(context).size;
    final photos = place.photos.isNotEmpty ? place.photos : null;
    final photoIdx = _photoIndex[_currentIndex] ?? 0;

    return SizedBox(
      height: (size.height * 0.66).roundToDouble(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.base,
            // Expand every child so BoxFit.cover fills the hero; the default
            // loose Stack letterboxes landscape photos.
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: [...previous, if (current != null) current],
            ),
            child:
                photos != null
                    ? Image.network(
                      photos[photoIdx].url,
                      key: ValueKey('${_currentIndex}_$photoIdx'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderBg(place),
                      loadingBuilder:
                          (ctx, child, prog) =>
                              prog == null ? child : _placeholderBg(place),
                    )
                    : _placeholderBg(place),
          ),

          // Text over photography always sits on a protection gradient.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.photoScrim),
            ),
          ),

          if (photos != null && photos.length > 1) ...[
            Positioned(
              top: 0,
              left: 0,
              right: size.width / 2,
              bottom: 140,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (photoIdx > 0) {
                    HapticFeedback.selectionClick();
                    setState(() => _photoIndex[_currentIndex] = photoIdx - 1);
                  }
                },
              ),
            ),
            Positioned(
              top: 0,
              left: size.width / 2,
              right: 0,
              bottom: 140,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (photoIdx < photos.length - 1) {
                    HapticFeedback.selectionClick();
                    setState(() => _photoIndex[_currentIndex] = photoIdx + 1);
                  }
                },
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 90,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(photos.length, (i) {
                    final active = photoIdx == i;
                    return AnimatedContainer(
                      duration: AppMotion.base,
                      curve: AppMotion.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 5,
                      decoration: BoxDecoration(
                        color:
                            active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  40,
                  AppSpacing.gutter,
                  // Clear the details sheet, which overlaps the hero's foot.
                  AppSpacing.x5 + AppRadius.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (place.cuisineType != null) ...[
                      _overPhotoPill(
                        Icons.local_dining_rounded,
                        place.cuisineType!,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                    ],
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (place.rating != null)
                          _overPhotoPill(
                            Icons.star_rounded,
                            '${place.ratingDisplay}  ${place.reviewCount}',
                            highlight: true,
                          ),
                        if (place.priceDisplay.isNotEmpty)
                          _overPhotoPill(
                            Icons.payments_outlined,
                            place.priceDisplay,
                          ),
                        if (place.isOpenNow != null)
                          _overPhotoPill(
                            place.isOpenNow!
                                ? Icons.schedule_rounded
                                : Icons.schedule_outlined,
                            place.openStatusDisplay,
                            fresh: place.isOpenNow!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: AppRadius.xxl,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                borderRadius: AppRadius.sheetTop,
              ),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderBg(Place place) {
    return Container(
      color: AppColors.sand800,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_rounded,
              color: Colors.white.withValues(alpha: 0.22),
              size: 54,
            ),
            const SizedBox(height: AppSpacing.x3),
            Text(
              place.name,
              style: AppTextStyles.small.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Glass chip for controls and stats floating over photography — the one
  /// place the design system allows blur.
  Widget _overPhotoPill(
    IconData icon,
    String text, {
    bool highlight = false,
    bool fresh = false,
  }) {
    final bg =
        highlight
            ? Colors.white.withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.18);
    final fg = highlight ? AppColors.textStrong : Colors.white;
    final iconColor =
        highlight
            ? AppColors.rating
            : (fresh ? AppColors.avocado300 : Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillAll,
        border:
            highlight
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTextStyles.captionStrong.copyWith(color: fg, height: 1),
          ),
        ],
      ),
    );
  }

  // ─── Details sheet ─────────────────────────────────────────────────────────

  Widget _buildDetails(Place place) {
    return Container(
      key: _detailsKey,
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.x2,
        AppSpacing.gutter,
        AppSpacing.x16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (place.address != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.place_outlined,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(place.address!, style: AppTextStyles.small),
                ),
              ],
            ),
          ],

          if (place.reviews.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x8),
            const SectionHeader(title: 'What people say'),
            const SizedBox(height: AppSpacing.x3),
            HangoutListGroup(
              children: [
                for (final r in place.reviews.take(3)) _ReviewTile(review: r),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Peeking next card ────────────────────────────────────────────────────────

class _PeekCard extends StatelessWidget {
  final Place place;

  const _PeekCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (place.mainPhotoUrl.isNotEmpty)
          Image.network(
            place.mainPhotoUrl,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => const ColoredBox(color: AppColors.sand800),
          )
        else
          const ColoredBox(color: AppColors.sand800),
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.photoScrim),
        ),
      ],
    );
  }
}

// ─── Review tile ──────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  final PlaceReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HangoutAvatar(name: review.authorName, size: 32),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionStrong,
                    ),
                    if (review.relativeTime != null)
                      Text(review.relativeTime!, style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (review.rating != null) HangoutBadge.rating(review.rating!),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x3),
            Text(
              review.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Waiting on the crew ──────────────────────────────────────────────────────

class _WaitingScreen extends StatefulWidget {
  final SessionModel session;
  final Group group;
  final SessionService service;

  const _WaitingScreen({
    required this.session,
    required this.group,
    required this.service,
  });

  @override
  State<_WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<_WaitingScreen> {
  StreamSubscription<({int membersFinished, int totalMembers})>? _sub;
  ({int membersFinished, int totalMembers})? _progress;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.service
        .watchGroupProgress(widget.session.id, widget.group.id)
        .listen((p) async {
          if (!mounted) return;
          setState(() => _progress = p);

          if (p.membersFinished >= p.totalMembers && !_navigating) {
            _navigating = true;
            try {
              final results = await widget.service.computeResults(
                widget.session.id,
              );
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder:
                      (_) => ResultsScreen(
                        session: widget.session,
                        group: widget.group,
                        service: widget.service,
                        precomputedResults: results,
                      ),
                ),
              );
            } catch (_) {
              if (mounted) setState(() => _navigating = false);
            }
          }
        });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _progress?.membersFinished ?? 0;
    final total = _progress?.totalMembers ?? widget.group.members.length;

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
          AppSpacing.x6,
          AppSpacing.gutter,
          AppSpacing.x8,
        ),
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 40,
            color: AppColors.accentFresh,
          ),
          const SizedBox(height: AppSpacing.x4),
          Text('You’re in ✓', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text(
            'Results land as soon as everyone in ${widget.group.name} is done '
            'swiping. We’ll bring you straight there.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.x8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: total > 0 ? done / total : 0,
                    ),
                    duration: AppMotion.slow,
                    curve: AppMotion.easeOut,
                    builder:
                        (context, v, _) => LinearProgressIndicator(
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
              Text('$done of $total done', style: AppTextStyles.smallStrong),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Results ──────────────────────────────────────────────────────────────────

class ResultsScreen extends StatefulWidget {
  final SessionModel session;
  final Group? group;
  /// Needed only to compute results that weren't passed in.
  final SessionService? service;
  final List<PlaceResult>? precomputedResults;

  const ResultsScreen({
    super.key,
    required this.session,
    required this.group,
    this.service,
    this.precomputedResults,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<PlaceResult>? _results;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.precomputedResults != null) {
      _results = widget.precomputedResults;
      _loading = false;
    } else {
      _compute();
    }
  }

  Future<void> _compute() async {
    try {
      final results = await (widget.service ?? SessionService())
          .computeResults(widget.session.id);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "We couldn't tally the votes.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: HangoutBackButton(
          icon: Icons.close_rounded,
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x8),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ),
      );
    }

    if (_results == null || _results!.isEmpty) {
      return Center(
        child: Text('Nobody voted yet.', style: AppTextStyles.body),
      );
    }

    final shown = _results!.take(10).toList();
    final winner = shown.first.isWinner ? shown.first : null;
    final rest = winner == null ? shown : shown.sublist(1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.x2,
        AppSpacing.gutter,
        AppSpacing.x10,
      ),
      children: [
        Text(
          winner != null ? 'It’s decided' : 'No clear winner',
          style: AppTextStyles.h1,
        ),
        const SizedBox(height: 4),
        Text(
          winner != null
              ? (widget.group != null
                  ? '${widget.group!.name} picked a place.'
                  : 'Here’s where you’re going.')
              : 'Nobody said yes to anything this round.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.x6),
        if (winner != null) _WinnerCard(result: winner, onBook: _openBooking),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x8),
          SectionHeader(title: winner != null ? 'Runners-up' : 'How it went'),
          const SizedBox(height: AppSpacing.x2),
          HangoutListGroup(
            children: [
              for (final r in rest)
                HangoutListRow(
                  leading: ClipRRect(
                    borderRadius: AppRadius.smAll,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: HangoutPhoto(url: r.place.mainPhotoUrl),
                    ),
                  ),
                  title: r.place.name,
                  subtitle: '${r.yesVotes} yes · ${r.noVotes} no',
                  trailing: Text(
                    '${r.votePercent.round()}%',
                    style: AppTextStyles.smallStrong,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openBooking(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// The payoff. The winner gets the full image-forward treatment and the one
/// primary action on the screen.
class _WinnerCard extends StatelessWidget {
  final PlaceResult result;
  final ValueChanged<String> onBook;

  const _WinnerCard({required this.result, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final place = result.place;
    final total = result.yesVotes + result.noVotes;

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
          AspectRatio(
            aspectRatio: 16 / 10,
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
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h2,
                ),
                if (place.address != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    place.address!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small,
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  total == 0
                      ? 'No votes recorded'
                      : '${result.yesVotes} of $total said yes',
                  style: AppTextStyles.smallStrong.copyWith(
                    color: AppColors.avocado700,
                  ),
                ),
                const SizedBox(height: AppSpacing.x5),
                HangoutButton(
                  label: 'Find it on Dineout',
                  size: HangoutButtonSize.lg,
                  block: true,
                  iconRight: Icons.open_in_new_rounded,
                  onPressed: () => onBook(place.dineoutUrl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
