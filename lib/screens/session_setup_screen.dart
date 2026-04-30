import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/group.dart';
import '../services/session_service.dart';
import 'location_picker_screen.dart';
import 'place_swipe_screen.dart';
import 'session_filters_screen.dart';

class SessionSetupScreen extends StatefulWidget {
  final Group? group;
  final String mode;

  const SessionSetupScreen({super.key, this.group, required this.mode});

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _service = SessionService();

  bool _loading = false;
  String? _error;
  LatLng? _pickedLatLng;

  late final AnimationController _btnAnim;
  late final Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _btnAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _btnAnim, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _btnAnim.dispose();
    super.dispose();
  }

  bool get _isHungerMode => widget.mode == 'hunger';
  Color get _accent => _isHungerMode ? const Color(0xFF1B6D01) : const Color(0xFF1E6BE6);
  Color get _accentDark => _isHungerMode ? const Color(0xFF0A3A00) : const Color(0xFF0A3888);
  String get _modeLabel => _isHungerMode ? 'Hunger' : 'Travel';
  String get _placeHint => _isHungerMode ? 'e.g. Banjara Hills, Hyderabad' : 'e.g. Charminar, Hyderabad';
  IconData get _modeIcon => _isHungerMode ? Icons.restaurant : Icons.explore;

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initialPosition: _pickedLatLng)),
    );
    if (result != null) {
      setState(() { _pickedLatLng = result; _error = null; _ctrl.clear(); });
    }
  }

  Future<void> _findPlaces() async {
    final hasMap = _pickedLatLng != null;
    final hasText = _ctrl.text.trim().isNotEmpty;

    if (!hasMap && !hasText) {
      setState(() => _error = 'Pick a location on the map or type an area name');
      return;
    }

    FocusScope.of(context).unfocus();

    // Show settings screen first; user confirms filters then we search
    final filters = await Navigator.of(context).push<SwipeFilters>(
      MaterialPageRoute(
        builder: (_) => SessionFiltersScreen(
          mode: widget.mode,
          initial: const SwipeFilters(),
        ),
      ),
    );

    // null means user pressed back — cancel
    if (!mounted || filters == null) return;

    setState(() { _loading = true; _error = null; });

    try {
      final session = await _service.createSession(
        groupId: widget.group?.id,
        mode: widget.mode,
        type: widget.group != null ? 'group' : 'solo',
      );

      final SessionModel populated;
      if (hasMap) {
        populated = await _service.generatePlacesByLatLng(
          session: session,
          lat: _pickedLatLng!.latitude,
          lng: _pickedLatLng!.longitude,
          radiusMeters: filters.radiusMeters,
          includedTypes: filters.placeTypes.isNotEmpty ? filters.placeTypes : null,
          maxPriceLevel: filters.maxPrice,
          openNowOnly: filters.openNowOnly,
        );
      } else {
        populated = await _service.generatePlaces(
          session: session,
          areaName: _ctrl.text.trim(),
          radiusMeters: filters.radiusMeters,
          includedTypes: filters.placeTypes.isNotEmpty ? filters.placeTypes : null,
          maxPriceLevel: filters.maxPrice,
          openNowOnly: filters.openNowOnly,
        );
      }

      if (!mounted) return;

      if (populated.places.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No ${_isHungerMode ? "restaurants" : "attractions"} found nearby. Try different filters or a different spot.';
        });
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PlaceSwipeScreen(session: populated, group: widget.group)),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [_buildHeader(), Expanded(child: _buildBody())],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(_modeIcon, color: _accent, size: 18),
                  const SizedBox(width: 6),
                  Text('$_modeLabel Mode',
                    style: TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 2),
                Text(
                  widget.group != null ? widget.group!.name : 'Solo Session',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_accent.withOpacity(0.22), _accent.withOpacity(0.04)]),
                border: Border.all(color: _accent.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(_modeIcon, color: _accent, size: 52),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _isHungerMode ? "Where should we\nlook for food?" : "Where should we\nexplore?",
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.25),
          ),
          const SizedBox(height: 28),

          // Map picker card
          GestureDetector(
            onTap: _openMapPicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _pickedLatLng != null ? _accent.withOpacity(0.12) : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _pickedLatLng != null ? _accent : Colors.white12,
                  width: _pickedLatLng != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: _accent.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.map_rounded, color: _accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pickedLatLng != null ? 'Location selected' : 'Pick on Map',
                          style: TextStyle(color: _pickedLatLng != null ? _accent : Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _pickedLatLng != null
                            ? '${_pickedLatLng!.latitude.toStringAsFixed(4)}, ${_pickedLatLng!.longitude.toStringAsFixed(4)}'
                            : 'Tap to open map and drop a pin',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _pickedLatLng != null ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                    color: _pickedLatLng != null ? _accent : Colors.white30,
                    size: _pickedLatLng != null ? 22 : 16,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Row(children: [
            const Expanded(child: Divider(color: Colors.white12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or type an area', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
            const Expanded(child: Divider(color: Colors.white12)),
          ]),

          const SizedBox(height: 16),

          // Text search
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _ctrl,
              enabled: !_loading,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.search,
              onChanged: (_) { if (_pickedLatLng != null) setState(() => _pickedLatLng = null); },
              onSubmitted: (_) => _findPlaces(),
              decoration: InputDecoration(
                hintText: _placeHint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF5C5C), size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFF5C5C), fontSize: 13))),
            ]),
          ],

          const SizedBox(height: 32),

          // Find button
          GestureDetector(
            onTapDown: (_) => _btnAnim.forward(),
            onTapUp: (_) { _btnAnim.reverse(); if (!_loading) _findPlaces(); },
            onTapCancel: () => _btnAnim.reverse(),
            child: ScaleTransition(
              scale: _btnScale,
              child: Container(
                width: double.infinity, height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(colors: [_accent, _accentDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: Center(
                  child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_isHungerMode ? Icons.restaurant : Icons.explore, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text('Find ${_isHungerMode ? "Restaurants" : "Places"}',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                      ]),
                ),
              ),
            ),
          ),

          if (widget.group != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(children: [
                Icon(Icons.group_outlined, color: _accent, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'All ${widget.group!.members.length} members in ${widget.group!.name} will swipe the same cards.',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4),
                )),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}