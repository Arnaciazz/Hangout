import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../l10n/l10n.dart';
import '../models/group.dart';
import '../services/places_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_card.dart';
import 'group_detail_screen.dart';
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

  /// A crew has one session going at a time. If there's one already, send the
  /// person to it rather than starting a second that nobody else sees.
  Future<bool> _crewAlreadyDeciding() async {
    final l10n = context.l10n;
    List<SessionSummary> active;
    try {
      active = await _service.getActiveSessions(widget.group!.id);
    } catch (_) {
      return false;
    }
    if (active.isEmpty || !mounted) return false;

    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.setupAlreadyDecidingTitle),
        content: Text(l10n.setupAlreadyDecidingBody(widget.group!.name),
            style: AppTextStyles.small),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel,
                style: AppTextStyles.smallStrong
                    .copyWith(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.setupAlreadyDecidingOpen,
                style:
                    AppTextStyles.smallStrong.copyWith(color: AppColors.brand)),
          ),
        ],
      ),
    );
    if (open == true && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => GroupDetailScreen(group: widget.group!),
      ));
    }
    return true;
  }

  Future<void> _findPlaces() async {
    // Group session: pick filters, then head to the lobby.
    if (widget.group != null) {
      FocusScope.of(context).unfocus();
      if (await _crewAlreadyDeciding() || !mounted) return;
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
          filters: filters,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => GroupSessionLobbyScreen(
            sessionId: session.id,
            group: widget.group!,
            mode: widget.mode,
            filters: filters,
            hostId: session.userId,
          ),
        ));
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = context.l10n.errorGeneric;
        });
      }
      return;
    }

    // Solo session: location, then filters, then places.
    final hasMap = _pickedLatLng != null;
    final hasText = _ctrl.text.trim().isNotEmpty;

    if (!hasMap && !hasText) {
      setState(() => _error = context.l10n.setupNeedPlace);
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
        filters: filters,
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
              ? context.l10n.setupNothingFood
              : context.l10n.setupNothingPlaces;
        });
        return;
      }

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) =>
            PlaceSwipeScreen(session: populated, group: widget.group),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is PlacesServiceException &&
                e.message.startsWith('Geocoding failed')
            ? context.l10n.setupAreaNotFound
            : context.l10n.errorGeneric;
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
          widget.group?.name ?? context.l10n.setupJustMe,
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
    final l10n = context.l10n;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.x2, AppSpacing.gutter, AppSpacing.x8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isHunger ? l10n.setupGroupTitleFood : l10n.setupGroupTitlePlaces,
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(l10n.setupHowItGoes, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.x6),
          _infoRow(Icons.place_rounded, l10n.setupStepPins),
          const SizedBox(height: AppSpacing.x3),
          _infoRow(Icons.swipe_rounded,
              l10n.setupStepSwipe(widget.group!.members.length)),
          const SizedBox(height: AppSpacing.x3),
          _infoRow(Icons.emoji_events_rounded, l10n.setupStepReveal),
          _buildError(),
          const SizedBox(height: AppSpacing.x8),
          HangoutButton(
            label: l10n.setupOpenLobby,
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
    final l10n = context.l10n;
    final picked = _pickedLatLng != null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.x2, AppSpacing.gutter, AppSpacing.x8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isHunger ? l10n.setupSoloTitleFood : l10n.setupSoloTitlePlaces,
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
                      Text(picked ? l10n.setupPinDropped : l10n.setupPickOnMap,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: picked ? _accent : AppColors.textStrong,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        picked
                            ? '${_pickedLatLng!.latitude.toStringAsFixed(4)}, ${_pickedLatLng!.longitude.toStringAsFixed(4)}'
                            : l10n.setupPickOnMapHint,
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
                child: Text(l10n.setupOrTypeArea, style: AppTextStyles.caption),
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
              hintText: _isHunger ? l10n.setupAreaHintFood : l10n.setupAreaHintPlaces,
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
            label: _isHunger ? l10n.setupFindFood : l10n.setupFindPlaces,
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
