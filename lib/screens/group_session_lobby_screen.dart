import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_avatar.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_list.dart';
import 'location_picker_screen.dart';
import 'place_swipe_screen.dart';
import 'session_filters_screen.dart';

/// The lobby for a group session in `setup`. Everyone drops a pin here; the
/// host can start swiping once the whole crew is in.
class GroupSessionLobbyScreen extends StatefulWidget {
  final String sessionId;
  final Group group;
  final String mode;
  final SwipeFilters filters;

  const GroupSessionLobbyScreen({
    super.key,
    required this.sessionId,
    required this.group,
    required this.mode,
    required this.filters,
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
  bool get _amOwner => widget.group.isOwner(_myId);

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
            builder: (_) =>
                PlaceSwipeScreen(session: session, group: widget.group),
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
        locationName: 'My location',
        radiusKm: widget.filters.radiusKm,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Couldn't save that pin."),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  Future<void> _startSession() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      await _service.startGroupSession(
        sessionId: widget.sessionId,
        groupId: widget.group.id,
        mode: widget.mode,
        filters: widget.filters,
      );
      // The status stream navigates everyone, including the host.
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
            ready ? 'Everyone’s in' : 'Drop your pins',
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.group.name} · ${_isHunger ? 'somewhere to eat' : 'somewhere to go'}',
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
              Text('$submitted of $total', style: AppTextStyles.smallStrong),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            'We search around the middle of everyone’s pins, so nobody '
            'has to cross town.',
            style: AppTextStyles.small,
          ),
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
    final hasAdded = _submittedIds.contains(m.userId);
    final isMe = m.userId == _myId;

    return HangoutListRow(
      leading: HangoutAvatar(
        name: m.displayName,
        imageUrl: m.avatarUrl,
        size: 40,
      ),
      title: isMe ? '${m.displayName} (you)' : m.displayName,
      subtitle: hasAdded ? 'Pin dropped' : 'Hasn’t dropped a pin yet',
      trailing: AnimatedSwitcher(
        duration: AppMotion.base,
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: hasAdded
            ? const Icon(Icons.check_circle_rounded,
                key: ValueKey(true), color: AppColors.accentFresh)
            : const Icon(Icons.radio_button_unchecked_rounded,
                key: ValueKey(false), color: AppColors.sand300),
      ),
    );
  }

  Widget _buildBottom() {
    final missing = widget.group.members.length - _submittedIds.length;

    // Exactly one primary at a time: drop your pin first; once it's in, the
    // host's "Start swiping" takes over.
    final pinButton = HangoutButton(
      label: _myLocationAdded ? 'Move my pin' : 'Drop my pin',
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
          if (_amOwner && _myLocationAdded) ...[
            HangoutButton(
              label: _allLocationsAdded
                  ? (_starting ? 'Finding places…' : 'Start swiping')
                  : 'Waiting on $missing more',
              size: HangoutButtonSize.lg,
              block: true,
              loading: _starting,
              onPressed: (_allLocationsAdded && !_starting && !_navigating)
                  ? _startSession
                  : null,
            ),
            const SizedBox(height: AppSpacing.x2),
          ],
          pinButton,
          if (!_amOwner && _myLocationAdded) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(
              _allLocationsAdded
                  ? 'Waiting for the host to start'
                  : 'Waiting on $missing more',
              style: AppTextStyles.small,
            ),
          ],
        ],
      ),
    );
  }
}
