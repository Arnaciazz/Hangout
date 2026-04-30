import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/place.dart';
import '../services/session_service.dart';

class PlaceSwipeScreen extends StatefulWidget {
  final SessionModel session;
  final Group? group;

  const PlaceSwipeScreen({super.key, required this.session, this.group});

  @override
  State<PlaceSwipeScreen> createState() => _PlaceSwipeScreenState();
}

class _PlaceSwipeScreenState extends State<PlaceSwipeScreen>
    with TickerProviderStateMixin {
  final SessionService _service = SessionService();

  int _currentIndex = 0;
  bool _swiping = false; // debounce

  // Photo index per card (tap left/right to navigate)
  final Map<int, int> _photoIndex = {};

  // Group realtime progress
  StreamSubscription<({int membersFinished, int totalMembers})>? _progressSub;
  ({int membersFinished, int totalMembers})? _groupProgress;

  // Drag state
  Offset _dragOffset = Offset.zero;
  bool _dragging = false;

  late final AnimationController _cardAnim;
  late final AnimationController _overlayAnim;

  String? _lastDirection; // 'yes' | 'no' shown as overlay

  List<Place> get _places => widget.session.places;
  Place? get _current =>
      _currentIndex < _places.length ? _places[_currentIndex] : null;

  @override
  void initState() {
    super.initState();
    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _overlayAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Start realtime progress tracking for group sessions
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
    _cardAnim.dispose();
    _overlayAnim.dispose();
    super.dispose();
  }

  // ── Swipe logic ────────────────────────────────────────────────────────────

  Future<void> _swipe(String direction) async {
    if (_swiping || _current == null) return;
    if (_current!.id == null) return; // no Supabase ID, can't record

    setState(() {
      _swiping = true;
      _lastDirection = direction;
    });

    _overlayAnim.forward(from: 0);

    try {
      await _service.recordSwipe(
        sessionId: widget.session.id,
        placeId: _current!.id!,
        direction: direction,
      );
    } catch (_) {
      // Swipe is fire-and-forget; network retry handled in background
    }

    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;
    setState(() {
      _currentIndex++;
      _dragOffset = Offset.zero;
      _lastDirection = null;
      _swiping = false;
    });
    _overlayAnim.reverse();

    // If all swiped → show results
    if (_currentIndex >= _places.length) {
      _showDone();
    }
  }

  void _showDone() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _ResultsScreen(
          session: widget.session,
          group: widget.group,
          service: _service,
        ),
      ),
    );
  }

  // ── Drag gesture ───────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (_swiping) return;
    setState(() => _dragging = true);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_dragging || _swiping) return;
    setState(() => _dragOffset += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_dragging) return;
    setState(() => _dragging = false);
    final threshold = MediaQuery.of(context).size.width * 0.35;
    if (_dragOffset.dx > threshold) {
      _swipe('yes');
    } else if (_dragOffset.dx < -threshold) {
      _swipe('no');
    } else {
      setState(() => _dragOffset = Offset.zero);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_places.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: Text('No places found.', style: TextStyle(color: Colors.white60)),
        ),
      );
    }

    if (_currentIndex >= _places.length) {
      // Replaced by results screen — show placeholder
      return const Scaffold(backgroundColor: Color(0xFF0D0D0D));
    }

    final place = _places[_currentIndex];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // ── Swipeable card ─────────────────────────────────────────────────
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: AnimatedContainer(
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              curve: Curves.elasticOut,
              transform: Matrix4.translationValues(
                _dragOffset.dx,
                _dragOffset.dy * 0.3,
                0,
              )..rotateZ(_dragOffset.dx / size.width * 0.2),
              child: _buildCard(place),
            ),
          ),

          // ── Progress bar ───────────────────────────────────────────────────
          _buildProgressBar(),

          // ── Swipe hint overlay (YES / NO indicator) ────────────────────────
          if (_lastDirection != null)
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: _overlayAnim,
                  child: _buildSwipeOverlay(_lastDirection!),
                ),
              ),
            ),

          // ── Back button ────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // ── Fixed bottom YES / NO buttons (Bumble-style) ───────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActions(),
          ),

          // ── Group realtime progress strip ──────────────────────────────────
          if (widget.group != null && _groupProgress != null)
            _buildGroupProgressStrip(_groupProgress!),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      color: const Color(0xFF0D0D0D),
      padding: EdgeInsets.fromLTRB(
          32, 16, 32, MediaQuery.of(context).padding.bottom + 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionBtn(
            Icons.close_rounded,
            const Color(0xFFFF5C5C),
            const Color(0xFF1A0A0A),
            size: 60,
            onTap: () => _swipe('no'),
          ),
          _actionBtn(
            Icons.favorite_rounded,
            Colors.white,
            const Color(0xFF1B6D01),
            size: 72,
            onTap: () => _swipe('yes'),
          ),
          _actionBtn(
            Icons.info_outline_rounded,
            Colors.white70,
            const Color(0xFF1A1A1A),
            size: 60,
            onTap: _scrollToDetails,
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
          padding: const EdgeInsets.fromLTRB(52, 16, 20, 0),
          child: Row(
            children: List.generate(_places.length, (i) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i < _currentIndex
                        ? Colors.white
                        : i == _currentIndex
                            ? Colors.white54
                            : Colors.white.withOpacity(0.18),
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

  Widget _buildSwipeOverlay(String direction) {
    final isYes = direction == 'yes';
    return Container(
      alignment: isYes ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isYes
              ? const Color(0xFF2B6C00).withOpacity(0.9)
              : const Color(0xFF8C1A00).withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isYes ? const Color(0xFF5AFF3A) : const Color(0xFFFF5C5C),
            width: 2,
          ),
        ),
        child: Text(
          isYes ? '❤️  YES' : '✕  NOPE',
          style: TextStyle(
            color: isYes ? const Color(0xFF5AFF3A) : const Color(0xFFFF5C5C),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupProgressStrip(({int membersFinished, int totalMembers}) progress) {
    final done = progress.membersFinished;
    final total = progress.totalMembers;
    final allDone = done >= total;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.black.withOpacity(0.55),
            padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            child: Row(
              children: [
                Icon(
                  allDone ? Icons.check_circle_rounded : Icons.people_alt_rounded,
                  color: allDone ? const Color(0xFF5AFF3A) : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        allDone
                            ? 'Everyone has voted!'
                            : '$done of $total members finished',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total > 0 ? done / total : 0,
                          minHeight: 4,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            allDone ? const Color(0xFF5AFF3A) : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Place place) {
    final bottomBarHeight = MediaQuery.of(context).padding.bottom + 112.0;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHero(place)),
        SliverToBoxAdapter(child: _buildDetails(place)),
        // space so content isn't hidden behind fixed bottom bar
        SliverToBoxAdapter(child: SizedBox(height: bottomBarHeight)),
      ],
    );
  }

  Widget _buildHero(Place place) {
    final size = MediaQuery.of(context).size;
    final photos = place.photos.isNotEmpty ? place.photos : null;
    final photoIdx = _photoIndex[_currentIndex] ?? 0;

    return SizedBox(
      height: size.height * 0.65,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Current photo with crossfade ────────────────────────────────
          // Use BoxFit.contain so landscape photos aren't cropped awkwardly;
          // dark background fills the letterbox areas.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: photos != null
                ? Image.network(
                    photos[photoIdx].url,
                    key: ValueKey('${_currentIndex}_$photoIdx'),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _placeholderBg(place),
                    loadingBuilder: (ctx, child, prog) =>
                        prog == null ? child : _placeholderBg(place),
                  )
                : _placeholderBg(place),
          ),

          // Gradient overlay
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.45, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // ── Tap left half / right half to navigate photos ───────────────
          if (photos != null && photos.length > 1) ...[
            Positioned(
              top: 0,
              left: 0,
              right: size.width / 2,
              bottom: 100,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (photoIdx > 0) {
                    setState(() => _photoIndex[_currentIndex] = photoIdx - 1);
                  }
                },
              ),
            ),
            Positioned(
              top: 0,
              left: size.width / 2,
              right: 0,
              bottom: 100,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (photoIdx < photos.length - 1) {
                    setState(() => _photoIndex[_currentIndex] = photoIdx + 1);
                  }
                },
              ),
            ),
          ],

          // ── Photo dot indicators ────────────────────────────────────────
          if (photos != null && photos.length > 1)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(photos.length, (i) {
                    final active = photoIdx == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ),

          // ── Place info overlay at bottom ─────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                      Colors.black.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (place.cuisineType != null)
                        _glassPill(Icons.local_dining, place.cuisineType!),
                      const SizedBox(height: 8),
                      Text(
                        place.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (place.rating != null) ...[
                            _glassPill(Icons.star, '${place.ratingDisplay} ${place.reviewCount}',
                                isHighlight: true),
                            const SizedBox(width: 8),
                          ],
                          if (place.priceDisplay.isNotEmpty)
                            _glassPill(Icons.currency_rupee, place.priceDisplay),
                          if (place.isOpenNow != null) ...[
                            const SizedBox(width: 8),
                            _glassPill(
                              place.isOpenNow! ? Icons.circle : Icons.circle_outlined,
                              place.openStatusDisplay,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  final _scrollKey = GlobalKey();
  void _scrollToDetails() {
    Scrollable.ensureVisible(
      _scrollKey.currentContext ?? context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  Widget _placeholderBg(Place place) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant, color: Colors.white24, size: 56),
            const SizedBox(height: 12),
            Text(
              place.name,
              style: const TextStyle(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassPill(IconData icon, String text, {bool isHighlight = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isHighlight
                ? const Color(0xFFFD5835).withOpacity(0.9)
                : Colors.white.withOpacity(0.15),
            border: Border.all(
                color: isHighlight ? const Color(0xFFFD5835) : Colors.white24),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: isHighlight ? const Color(0xFF570C00) : Colors.white,
                  size: 16),
              const SizedBox(width: 5),
              Text(
                text,
                style: TextStyle(
                  color: isHighlight ? const Color(0xFF570C00) : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, Color bg,
      {double size = 56, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30),
            ),
            child: Icon(icon, color: color, size: size * 0.44),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(Place place) {
    return Container(
      key: _scrollKey,
      color: const Color(0xFFFCF9F8),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E2E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Address
          if (place.address != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    color: Color(0xFF999999), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place.address!,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Reviews
          if (place.reviews.isNotEmpty) ...[
            const Text(
              'What people say',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1B1B),
              ),
            ),
            const SizedBox(height: 14),
            ...place.reviews.take(3).map((r) => _buildReviewTile(r)),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTile(PlaceReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF0EEE8),
                child: Text(
                  review.authorName.isNotEmpty
                      ? review.authorName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF555555),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1B1B),
                      ),
                    ),
                    if (review.relativeTime != null)
                      Text(
                        review.relativeTime!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF999999),
                        ),
                      ),
                  ],
                ),
              ),
              if (review.rating != null)
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFD5835), size: 14),
                    const SizedBox(width: 3),
                    Text(
                      review.rating!.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1B1B),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF555555),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Results Screen
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsScreen extends StatefulWidget {
  final SessionModel session;
  final Group? group;
  final SessionService service;

  const _ResultsScreen({
    required this.session,
    required this.group,
    required this.service,
  });

  @override
  State<_ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<_ResultsScreen> {
  List<PlaceResult>? _results;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _compute();
  }

  Future<void> _compute() async {
    try {
      final results = await widget.service.computeResults(widget.session.id);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Results',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white70),
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFD5835)));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!,
            style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
      );
    }
    if (_results == null || _results!.isEmpty) {
      return const Center(
        child: Text('No results yet.',
            style: TextStyle(color: Colors.white54, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: _results!.length,
      itemBuilder: (ctx, i) => _buildResultTile(_results![i], i),
    );
  }

  Widget _buildResultTile(PlaceResult r, int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: r.isWinner
            ? const Color(0xFFFD5835).withOpacity(0.12)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: r.isWinner
              ? const Color(0xFFFD5835).withOpacity(0.5)
              : Colors.white12,
          width: r.isWinner ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: r.isWinner
                  ? const Color(0xFFFD5835)
                  : Colors.white.withOpacity(0.08),
            ),
            child: Center(
              child: r.isWinner
                  ? const Text('🏆', style: TextStyle(fontSize: 18))
                  : Text(
                      '${r.rank}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Photo thumbnail
          if (r.place.mainPhotoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                r.place.mainPhotoUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(width: 52, height: 52),
              ),
            ),
          const SizedBox(width: 14),

          // Name + vote info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.place.name,
                  style: TextStyle(
                    color: r.isWinner ? Colors.white : Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${r.yesVotes} ❤️  •  ${r.noVotes} ✕',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),

          // Vote percentage
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: r.isWinner
                  ? const Color(0xFFFD5835).withOpacity(0.2)
                  : Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${r.votePercent.round()}%',
              style: TextStyle(
                color: r.isWinner ? const Color(0xFFFD5835) : Colors.white54,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
