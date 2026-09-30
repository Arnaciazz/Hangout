import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../models/group.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_avatar.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_list.dart';
import 'location_picker_screen.dart';
import 'place_swipe_screen.dart';
import 'session_filters_screen.dart';

/// The lobby for a group session in `setup`. Everyone drops a pin here; the
/// host — whoever started the session — starts swiping when enough pins are
/// in. Nobody who's missing holds the crew up.
class GroupSessionLobbyScreen extends StatefulWidget {
  final String sessionId;
  final Group group;
  final String mode;
  final SwipeFilters filters;

  /// The session's creator. Only they can start it (the database agrees).
  final String hostId;

  const GroupSessionLobbyScreen({
    super.key,
    required this.sessionId,
    required this.group,
    required this.mode,
    required this.filters,
    required this.hostId,
  });

  @override
  State<GroupSessionLobbyScreen> createState() =>
      _GroupSessionLobbyScreenState();
}

class _GroupSessionLobbyScreenState extends State<GroupSessionLobbyScreen> {
  final _service = SessionService();

  List<SessionLocation> _locations = [];
  bool _myLocationAdded = false;
  bool _starting = false;
  bool _navigating = false;

  StreamSubscription<List<SessionLocation>>? _locationSub;
  StreamSubscription<String>? _statusSub;

  bool get _isHunger => widget.mode == 'hunger';
  String get _myId => Supabase.instance.client.auth.currentUser!.id;
  bool get _amHost => widget.hostId == _myId;

  Set<String> get _submittedIds => _locations.map((l) => l.addedBy).toSet();

  bool get _allLocationsAdded =>
      widget.group.members.every((m) => _submittedIds.contains(m.userId));

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _locationSub =
        _service.watchSessionLocations(widget.sessionId).listen((locs) {
      if (!mounted) return;
      setState(() {
        _locations = locs;
        _myLocationAdded = _submittedIds.contains(_myId);
      });
    });

    _statusSub =
        _service.watchSessionStatus(widget.sessionId).listen((status) async {
      if (!mounted || _navigating) return;
      if (status == 'swiping') {
        _navigating = true;
        try {
          final session = await _service.getSessionWithPlaces(widget.sessionId);
          if (!mounted) return;
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => PlaceSwipeScreen(
              session: session,
              group: widget.group,
              resume: true,
            ),
          ));
        } catch (_) {
          if (mounted) setState(() => _navigating = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result == null || !mounted) return;

    try {
      await _service.addUserLocation(
        sessionId: widget.sessionId,
        lat: result.latitude,
        lng: result.longitude,
        locationName: context.l10n.lobbyMyPin,
        radiusKm: widget.filters.radiusKm,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.lobbyPinFailed),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  Future<void> _startSession() async {
    if (_starting) return;
    final l10n = context.l10n;
    final missing = widget.group.members.length - _submittedIds.length;
    if (missing > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.lobbyStartEarlyTitle),
          content: Text(l10n.lobbyStartEarlyBody(missing),
              style: AppTextStyles.small),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.lobbyStartEarlyWait,
                  style: AppTextStyles.smallStrong
                      .copyWith(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.lobbyStartEarlyConfirm,
                  style: AppTextStyles.smallStrong
                      .copyWith(color: AppColors.brand)),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _starting = true);
    try {
      await _service.startGroupSession(
        sessionId: widget.sessionId,
        groupId: widget.group.id,
        mode: widget.mode,
        filters: widget.filters,
      );
      // The status stream navigates everyone, including the host.
    } catch (e) {
      if (!mounted) return;
      setState(() => _starting = false);
      final l10n = context.l10n;
      final message = e.toString().contains('No ')
          ? (_isHunger ? l10n.lobbyNothingFoodNearby : l10n.lobbyNothingNearby)
          : l10n.errorGeneric;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final submitted = _submittedIds.length;
    final total = widget.group.members.length;
    final ready = _allLocationsAdded;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(leading: const HangoutBackButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter, AppSpacing.x2, AppSpacing.gutter, AppSpacing.x8),
        children: [
          Text(
            ready ? l10n.lobbyEveryoneIn : l10n.lobbyDropPins,
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: 4),
          Text(
            _isHunger
                ? l10n.lobbySubtitleFood(widget.group.name)
                : l10n.lobbySubtitlePlaces(widget.group.name),
            style: AppTextStyles.small,
          ),
          const SizedBox(height: AppSpacing.x6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                        begin: 0, end: total == 0 ? 0 : submitted / total),
                    duration: AppMotion.slow,
                    curve: AppMotion.easeOut,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceSunken,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ready ? AppColors.accentFresh : AppColors.brand,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Text(l10n.countOf(submitted, total),
                  style: AppTextStyles.smallStrong),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(l10n.lobbyMidpoint, style: AppTextStyles.small),
          const SizedBox(height: AppSpacing.x8),
          HangoutListGroup(
            children: [
              for (final m in widget.group.members) _memberRow(m),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottom(),
    );
  }

  Widget _memberRow(GroupMember m) {
    final l10n = context.l10n;
    final hasAdded = _submittedIds.contains(m.userId);
    final isMe = m.userId == _myId;

    return HangoutListRow(
      leading: HangoutAvatar(
        name: m.displayName,
        imageUrl: m.avatarUrl,
        size: 40,
      ),
      title: isMe ? l10n.nameYou(m.displayName) : m.displayName,
      subtitle: hasAdded ? l10n.lobbyPinDropped : l10n.lobbyNoPinYet,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (m.userId == widget.hostId) ...[
            HangoutBadge(label: l10n.badgeHost, tone: BadgeTone.warm),
            const SizedBox(width: AppSpacing.x2),
          ],
          AnimatedSwitcher(
            duration: AppMotion.base,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: hasAdded
                ? const Icon(Icons.check_circle_rounded,
                    key: ValueKey(true), color: AppColors.accentFresh)
                : const Icon(Icons.radio_button_unchecked_rounded,
                    key: ValueKey(false), color: AppColors.sand300),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    final l10n = context.l10n;
    final missing = widget.group.members.length - _submittedIds.length;

    // Exactly one primary at a time: drop your pin first; once it's in, the
    // host's "Start swiping" takes over.
    final pinButton = HangoutButton(
      label: _myLocationAdded ? l10n.lobbyMovePin : l10n.lobbyDropPin,
      size: HangoutButtonSize.lg,
      block: true,
      variant: _myLocationAdded
          ? HangoutButtonVariant.secondary
          : HangoutButtonVariant.primary,
      iconLeft: _myLocationAdded
          ? Icons.edit_location_alt_rounded
          : Icons.add_location_alt_rounded,
      onPressed: _navigating ? null : _pickLocation,
    );

    return StickyActionBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_amHost && _myLocationAdded) ...[
            HangoutButton(
              label: _starting
                  ? l10n.lobbyFindingPlaces
                  : (_allLocationsAdded
                      ? l10n.lobbyStartSwiping
                      : l10n.lobbyStartWithPins(_submittedIds.length)),
              size: HangoutButtonSize.lg,
              block: true,
              loading: _starting,
              onPressed: (!_starting && !_navigating) ? _startSession : null,
            ),
            const SizedBox(height: AppSpacing.x2),
          ],
          pinButton,
          if (!_amHost && _myLocationAdded) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(
              _allLocationsAdded
                  ? l10n.lobbyWaitingForHost
                  : l10n.lobbyWaitingOn(missing),
              style: AppTextStyles.small,
            ),
          ],
        ],
      ),
    );
  }
}
