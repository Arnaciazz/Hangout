import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';

/// A finished hangout: a session that reached results, with the place that won.
class HangoutMemory {
  final String sessionId;
  final String mode; // 'hunger' | 'travel'
  final String? groupId; // null for a solo session
  final String? groupName; // null for a solo session
  final DateTime date;
  final Place? winner; // null when nobody voted yes on anything
  final int yesVotes;
  final int noVotes;

  const HangoutMemory({
    required this.sessionId,
    required this.mode,
    this.groupId,
    required this.groupName,
    required this.date,
    required this.winner,
    required this.yesVotes,
    required this.noVotes,
  });

  bool get isSolo => groupId == null && groupName == null;
}

/// A session still in progress that the user can act on.
class ActiveHangout {
  final String sessionId;
  final String mode;
  final String status; // 'setup' | 'swiping'
  final String? groupId;
  final String? groupName;

  const ActiveHangout({
    required this.sessionId,
    required this.mode,
    required this.status,
    required this.groupId,
    required this.groupName,
  });
}

/// Read-only queries behind Home, Memories and Profile.
///
/// Scope is "sessions I can act on or remember": every session in a crew I
/// belong to, plus solo sessions I started. Nothing here writes — in
/// particular it reads the persisted `session_results` rather than calling
/// `SessionService.computeResults`, which re-saves results and moves
/// `completed_at` every time it runs.
class HistoryService {
  final SupabaseClient _db = Supabase.instance.client;

  String? get _uid => _db.auth.currentUser?.id;

  Future<List<String>> _myGroupIds() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows =
        await _db.from('group_members').select('group_id').eq('user_id', uid);
    return [for (final r in rows as List) r['group_id'] as String];
  }

  /// PostgREST `or` filter: sessions in my crews, or sessions I created.
  String _scope(String uid, List<String> groupIds) => groupIds.isEmpty
      ? 'user_id.eq.$uid'
      : 'group_id.in.(${groupIds.join(',')}),user_id.eq.$uid';

  /// Session ids this person marked "Didn't go".
  Future<Set<String>> _dismissedIds() async {
    final uid = _uid;
    if (uid == null) return const {};
    final rows = await _db
        .from('memory_dismissals')
        .select('session_id')
        .eq('user_id', uid);
    return {for (final r in rows as List) r['session_id'] as String};
  }

  /// "Didn't go": hide a hangout from this person's memories and counts.
  Future<void> dismiss(String sessionId) async {
    await _db.from('memory_dismissals').upsert(
      {'session_id': sessionId, 'user_id': _uid},
      onConflict: 'session_id,user_id',
    );
  }

  /// Undo a "Didn't go".
  Future<void> undoDismiss(String sessionId) async {
    await _db
        .from('memory_dismissals')
        .delete()
        .eq('session_id', sessionId)
        .eq('user_id', _uid!);
  }

  /// Finished hangouts, newest first, minus any marked "Didn't go".
  Future<List<HangoutMemory>> fetchMemories({int limit = 40}) async {
    final uid = _uid;
    if (uid == null) return const [];

    final (groupIds, dismissed) = await (_myGroupIds(), _dismissedIds()).wait;
    final rows = await _db
        .from('sessions')
        .select(
          'id, mode, group_id, created_at, completed_at, groups(name), '
          'session_results(yes_votes, no_votes, is_winner, '
          'suggested_places(id, google_place_id, name, address, rating, '
          'price_level, photos, cuisine_type, google_maps_uri))',
        )
        .inFilter('status', ['revealed', 'completed'])
        .or(_scope(uid, groupIds))
        .eq('session_results.is_winner', true)
        .order('completed_at', ascending: false, nullsFirst: false)
        .limit(limit);

    return [
      for (final r in rows as List)
        if (!dismissed.contains(r['id'])) _memoryFrom(r as Map<String, dynamic>),
    ];
  }

  HangoutMemory _memoryFrom(Map<String, dynamic> r) {
    final results = (r['session_results'] as List?) ?? const [];
    final winnerRow = results.cast<Map<String, dynamic>?>().firstWhere(
          (x) => x?['is_winner'] == true,
          orElse: () => null,
        );
    final placeJson = winnerRow?['suggested_places'] as Map<String, dynamic>?;

    return HangoutMemory(
      sessionId: r['id'] as String,
      mode: r['mode'] as String? ?? 'hunger',
      groupId: r['group_id'] as String?,
      groupName: (r['groups'] as Map<String, dynamic>?)?['name'] as String?,
      date: DateTime.parse(
        (r['completed_at'] ?? r['created_at']) as String,
      ).toLocal(),
      winner: placeJson == null ? null : Place.fromSupabaseJson(placeJson),
      yesVotes: winnerRow?['yes_votes'] as int? ?? 0,
      noVotes: winnerRow?['no_votes'] as int? ?? 0,
    );
  }

  /// The most recent session still in setup or swiping, if any.
  Future<ActiveHangout?> fetchActive() async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final groupIds = await _myGroupIds();
      final row = await _db
          .from('sessions')
          .select('id, mode, status, group_id, groups(name)')
          .inFilter('status', ['setup', 'swiping'])
          .or(_scope(uid, groupIds))
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;

      return ActiveHangout(
        sessionId: row['id'] as String,
        mode: row['mode'] as String? ?? 'hunger',
        status: row['status'] as String,
        groupId: row['group_id'] as String?,
        groupName: (row['groups'] as Map<String, dynamic>?)?['name'] as String?,
      );
    } catch (e) {
      debugPrint('[HistoryService] fetchActive: $e');
      return null;
    }
  }

  /// How many hangouts reached a result (minus "Didn't go"), and how many
  /// crews I'm in.
  Future<({int hangouts, int crews})> fetchCounts() async {
    final uid = _uid;
    if (uid == null) return (hangouts: 0, crews: 0);

    try {
      final (groupIds, dismissed) = await (_myGroupIds(), _dismissedIds()).wait;
      final rows = await _db
          .from('sessions')
          .select('id')
          .inFilter('status', ['revealed', 'completed'])
          .or(_scope(uid, groupIds));
      final hangouts =
          (rows as List).where((r) => !dismissed.contains(r['id'])).length;
      return (hangouts: hangouts, crews: groupIds.length);
    } catch (e) {
      debugPrint('[HistoryService] fetchCounts: $e');
      return (hangouts: 0, crews: 0);
    }
  }
}
