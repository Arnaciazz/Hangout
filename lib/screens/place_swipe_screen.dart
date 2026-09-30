import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/group.dart';
import '../models/place.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_list.dart';
import 'place_detail_screen.dart';
import 'results_screen.dart';
import 'reveal_screen.dart';

export 'results_screen.dart' show ResultsScreen;

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

  /// Pick up after the places this person already swiped (reopening a
  /// session). Off for a session that was just dealt.
  final bool resume;

  const PlaceSwipeScreen({
    super.key,
    required this.session,
    this.group,
    this.service,
    this.resume = false,
  });

  @override
  State<PlaceSwipeScreen> createState() => _PlaceSwipeScreenState();
}

class _PlaceSwipeScreenState extends State<PlaceSwipeScreen>
    with TickerProviderStateMixin {
  late final SessionService _service = widget.service ?? SessionService();

  int _currentIndex = 0;
  bool _swiping = false;

  /// Resuming: waiting to learn which places were already swiped.
  late bool _loadingSwipes = widget.resume;

  /// Out of cards: saving the last swipes and working out where to go.
  bool _finishing = false;
  bool _saveFailed = false;

  /// Swipes still being saved, and ones that gave up after retrying.
  final List<Future<void>> _inFlight = [];
  final Map<String, String> _unsaved = {};

  final Map<int, int> _photoIndex = {};

  StreamSubscription<CrewProgress>? _progressSub;
  StreamSubscription<String>? _statusSub;
  CrewProgress? _groupProgress;
  bool _leaving = false;

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
          .watchCrewProgress(widget.session.id, g.id)
          .listen((p) {
            if (mounted) setState(() => _groupProgress = p);
          }, onError: (_) {});
      // The host can reveal before everyone's done; follow them there.
      _statusSub = _service.watchSessionStatus(widget.session.id).listen((st) {
        if (st == 'revealed' || st == 'completed') _goToResults(celebrate: true);
      }, onError: (_) {});
    }
    if (widget.resume) _skipSwiped();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _statusSub?.cancel();
    _flyCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _skipSwiped() async {
    try {
      final mine = await _service.getMySwipes(widget.session.id);
      if (!mounted) return;
      final next = _places.indexWhere((p) => !mine.containsKey(p.id));
      setState(() {
        _currentIndex = next == -1 ? _places.length : next;
        _loadingSwipes = false;
      });
      if (next == -1) _finish();
    } catch (_) {
      // Start from the top; swipes are upserts, so repeats are harmless.
      if (mounted) setState(() => _loadingSwipes = false);
    }
  }

  /// Saves one swipe, retrying a couple of times before giving up on it.
  Future<void> _record(String placeId, String direction) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _service.recordSwipe(
          sessionId: widget.session.id,
          placeId: placeId,
          direction: direction,
        );
        _unsaved.remove(placeId);
        return;
      } catch (_) {
        await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    _unsaved[placeId] = direction;
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
    _inFlight.add(_record(_current!.id!, direction));

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

    if (_currentIndex >= _places.length) _finish();
  }

  /// Out of cards. Make sure every swipe is saved, then: a crew waits for the
  /// host's reveal; a solo swiper goes straight to their picks.
  Future<void> _finish() async {
    setState(() {
      _finishing = true;
      _saveFailed = false;
    });

    await Future.wait(_inFlight);
    _inFlight.clear();
    for (final e in Map.of(_unsaved).entries) {
      await _record(e.key, e.value);
    }
    if (!mounted) return;
    if (_unsaved.isNotEmpty) {
      setState(() => _saveFailed = true);
      return;
    }

    if (widget.group != null) {
      if (_leaving) return;
      _leaving = true;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => RevealScreen(
          session: widget.session,
          group: widget.group!,
          service: _service,
        ),
      ));
      return;
    }

    try {
      final results = await _service.computeResults(widget.session.id);
      if (!mounted) return;
      _goToResults(results: results);
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  void _goToResults({List<PlaceResult>? results, bool celebrate = false}) {
    if (_leaving || !mounted) return;
    _leaving = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultsScreen(
        session: widget.session,
        group: widget.group,
        service: _service,
        precomputedResults: results,
        celebrate: celebrate,
      ),
    ));
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
    final l10n = context.l10n;

    if (_places.isEmpty) {
      return _DarkMessage(
        title: l10n.swipeNothingTitle,
        body: l10n.swipeNothingBody,
      );
    }

    if (_saveFailed) {
      return _DarkMessage(
        title: l10n.swipeSaveFailedTitle,
        body: l10n.errorCheckConnection,
        action: HangoutButton(
          label: l10n.actionTryAgain,
          onPressed: _finish,
        ),
      );
    }

    if (_loadingSwipes || _finishing || _currentIndex >= _places.length) {
      return const Scaffold(
        backgroundColor: AppColors.surfaceInverse,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.textOnDark),
        ),
      );
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
                tooltip: l10n.actionClose,
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
                        isYes ? context.l10n.swipeYes : context.l10n.swipeNo,
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
    final l10n = context.l10n;

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
              tooltip: l10n.swipePass,
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
              tooltip: l10n.swipeYes,
              variant: HangoutIconButtonVariant.fresh,
              onPressed: _swiping ? null : () => _swipe('yes'),
            ),
          ),
          HangoutIconButton(
            icon: Icons.info_outline_rounded,
            size: 58,
            tooltip: l10n.swipeDetails,
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

  Widget _buildGroupProgressStrip(CrewProgress progress) {
    final done = progress.finished;
    final total = progress.total;
    final allDone = progress.allDone;
    final l10n = context.l10n;

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
                  allDone
                      ? l10n.swipeCrewAllDone
                      : l10n.swipeCrewProgress(done, total),
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
                            place.isOpenNow!
                                ? context.l10n.placeOpenNow
                                : context.l10n.placeClosed,
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
            SectionHeader(title: context.l10n.placeReviewsTitle),
            const SizedBox(height: AppSpacing.x3),
            HangoutListGroup(
              children: [
                for (final r in place.reviews.take(3)) ReviewTile(review: r),
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

// ─── Messages on the dark stage ───────────────────────────────────────────────

class _DarkMessage extends StatelessWidget {
  final String title;
  final String body;
  final Widget? action;

  const _DarkMessage({required this.title, required this.body, this.action});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceInverse,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: HangoutIconButton(
          icon: Icons.close_rounded,
          iconColor: AppColors.textOnDark,
          tooltip: context.l10n.actionClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.x8,
          AppSpacing.gutter,
          AppSpacing.x8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.h2.copyWith(color: AppColors.textOnDark),
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              body,
              style: AppTextStyles.body.copyWith(color: AppColors.sand300),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.x5),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
