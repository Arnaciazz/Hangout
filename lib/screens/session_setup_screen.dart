import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/group.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_card.dart';
import 'group_session_lobby_screen.dart';
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

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  final _ctrl = TextEditingController();
  final _service = SessionService();

  bool _loading = false;
  String? _error;
  LatLng? _pickedLatLng;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isHunger => widget.mode == 'hunger';
  // One action colour app-wide; the mode is carried by icon and words.
  static const _accent = AppColors.brand;
  static const _accentTint = AppColors.brandTint;
  IconData get _modeIcon =>
      _isHunger ? Icons.restaurant_rounded : Icons.explore_rounded;
  String get _placeHint =>
      _isHunger ? 'Banjara Hills, Hyderabad' : 'Charminar, Hyderabad';
  HangoutButtonVariant get _ctaVariant => HangoutButtonVariant.primary;

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialPosition: _pickedLatLng),
      ),
    );
    if (result != null) {
      setState(() {
        _pickedLatLng = result;
        _error = null;
        _ctrl.clear();
      });
    }
  }

  Future<void> _findPlaces() async {
    // Group session: pick filters, then head to the lobby.
    if (widget.group != null) {
      FocusScope.of(context).unfocus();
      final filters = await Navigator.of(context).push<SwipeFilters>(
        MaterialPageRoute(
          builder: (_) => SessionFiltersScreen(
            mode: widget.mode,
            initial: const SwipeFilters(),
          ),
        ),
      );
      if (!mounted || filters == null) return;

      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final session = await _service.createSession(
          groupId: widget.group!.id,
          mode: widget.mode,
          type: 'group',
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => GroupSessionLobbyScreen(
            sessionId: session.id,
            group: widget.group!,
            mode: widget.mode,
            filters: filters,
          ),
        ));
      } on Exception catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
      return;
    }

    // Solo session: location, then filters, then places.
    final hasMap = _pickedLatLng != null;
    final hasText = _ctrl.text.trim().isNotEmpty;

    if (!hasMap && !hasText) {
      setState(() => _error = 'Drop a pin, or type an area name.');
      return;
    }

    FocusScope.of(context).unfocus();

    final filters = await Navigator.of(context).push<SwipeFilters>(
      MaterialPageRoute(
        builder: (_) => SessionFiltersScreen(
          mode: widget.mode,
          initial: const SwipeFilters(),
        ),
      ),
    );
    if (!mounted || filters == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

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
          includedTypes:
              filters.placeTypes.isNotEmpty ? filters.placeTypes : null,
          maxPriceLevel: filters.maxPrice,
          openNowOnly: filters.openNowOnly,
        );
      } else {
        populated = await _service.generatePlaces(
          session: session,
          areaName: _ctrl.text.trim(),
          radiusMeters: filters.radiusMeters,
          includedTypes:
              filters.placeTypes.isNotEmpty ? filters.placeTypes : null,
          maxPriceLevel: filters.maxPrice,
          openNowOnly: filters.openNowOnly,
        );
      }

      if (!mounted) return;

      if (populated.places.isEmpty) {
        setState(() {
          _loading = false;
          _error = _isHunger
              ? "Nothing open around there. Try a wider radius?"
              : "Nothing around there. Try a wider radius?";
        });
        return;
      }

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) =>
            PlaceSwipeScreen(session: populated, group: widget.group),
      ));
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: const HangoutBackButton(),
        title: Text(
          widget.group?.name ?? 'Just me',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.title,
        ),
      ),
      body: SafeArea(
        top: false,
        child: widget.group != null ? _buildGroupBody() : _buildSoloBody(),
      ),
    );
  }

  Widget _buildError() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(_error!,
                style: AppTextStyles.small.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  // ─── Group flow ────────────────────────────────────────────────────────────

  Widget _buildGroupBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.x2, AppSpacing.gutter, AppSpacing.x8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isHunger ? 'Find food together' : 'Find a spot together',
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: AppSpacing.x3),
          const SizedBox(height: AppSpacing.x2),
          Text('Here’s how it goes.', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.x6),
          _infoRow(Icons.place_rounded,
              'Everyone drops a pin in the lobby'),
          const SizedBox(height: AppSpacing.x3),
          _infoRow(Icons.swipe_rounded,
              'All ${widget.group!.members.length} of you swipe the same places'),
          const SizedBox(height: AppSpacing.x3),
          _infoRow(Icons.emoji_events_rounded,
              'The place most of you want wins'),
          _buildError(),
          const SizedBox(height: AppSpacing.x8),
          HangoutButton(
            label: 'Open the lobby',
            size: HangoutButtonSize.lg,
            block: true,
            loading: _loading,
            variant: _ctaVariant,
            onPressed: _findPlaces,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: AppSpacing.x3),
        Expanded(child: Text(text, style: AppTextStyles.body)),
      ],
    );
  }

  // ─── Solo flow ─────────────────────────────────────────────────────────────

  Widget _buildSoloBody() {
    final picked = _pickedLatLng != null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.x2, AppSpacing.gutter, AppSpacing.x8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isHunger ? 'Where are you eating?' : 'Where are you headed?',
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: AppSpacing.x6),

          HangoutCard(
            radius: AppRadius.lg,
            color: picked ? _accentTint : AppColors.surface,
            border: Border.all(
              color: picked ? _accent : AppColors.border,
              width: picked ? 1.5 : 1,
            ),
            padding: const EdgeInsets.all(AppSpacing.x4),
            onTap: _openMapPicker,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.14),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Icon(Icons.map_rounded, color: _accent, size: 22),
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(picked ? 'Pin dropped' : 'Pick on the map',
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: picked ? _accent : AppColors.textStrong,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        picked
                            ? '${_pickedLatLng!.latitude.toStringAsFixed(4)}, ${_pickedLatLng!.longitude.toStringAsFixed(4)}'
                            : 'Open the map and drop a pin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppMotion.base,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    picked
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    key: ValueKey(picked),
                    color: picked ? _accent : AppColors.textFaint,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.x4),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
                child: Text('or type an area', style: AppTextStyles.caption),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),

          TextField(
            controller: _ctrl,
            enabled: !_loading,
            style: AppTextStyles.body.copyWith(color: AppColors.textStrong),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.search,
            onChanged: (_) {
              if (_pickedLatLng != null) {
                setState(() => _pickedLatLng = null);
              }
            },
            onSubmitted: (_) => _findPlaces(),
            decoration: InputDecoration(
              hintText: _placeHint,
              prefixIcon: const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 10, 0),
                child: Icon(Icons.search_rounded,
                    size: 20, color: AppColors.textFaint),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: BorderSide(color: _accent, width: 1.5),
              ),
            ),
          ),

          _buildError(),
          const SizedBox(height: AppSpacing.x8),

          HangoutButton(
            label: _isHunger ? 'Find places to eat' : 'Find places to go',
            size: HangoutButtonSize.lg,
            block: true,
            loading: _loading,
            iconLeft: _modeIcon,
            variant: _ctaVariant,
            onPressed: _findPlaces,
          ),
        ],
      ),
    );
  }
}
