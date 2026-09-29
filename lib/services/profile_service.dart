import 'package:supabase_flutter/supabase_flutter.dart';

class UserStats {
  final int sessionsCompleted;
  final int groupsJoined;
  final double totalSavings; // gamified: sessions × $8.50
  final String favoriteVibe; // mode used most: 'hunger' | 'travel'

  const UserStats({
    required this.sessionsCompleted,
    required this.groupsJoined,
    required this.totalSavings,
    required this.favoriteVibe,
  });
}

class ProfileService {
  final SupabaseClient _db = Supabase.instance.client;

  String? get _uid => _db.auth.currentUser?.id;

  // ── Setup gate ─────────────────────────────────────────────────────────────

  /// Returns true if the user has already chosen a nickname (onboarding done).
  Future<bool> hasCompletedSetup() async {
    if (_uid == null) return false;
    try {
      final row = await _db
          .from('profiles')
          .select('nickname')
          .eq('id', _uid!)
          .maybeSingle();
      return row != null && row['nickname'] != null;
    } catch (_) {
      return false;
    }
  }

  /// Persists the nickname and avatar choice to the profiles table.
  Future<void> saveNicknameAndAvatar({
    required String nickname,
    required int avatarId,
  }) async {
    if (_uid == null) return;
    final user = _db.auth.currentUser;
    final displayName = user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String? ??
        user?.email?.split('@').first ??
        nickname;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String? ??
        user?.userMetadata?['picture'] as String?;

    await _db.from('profiles').upsert({
      'id': _uid!,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'nickname': nickname,
      'avatar_id': avatarId,
    });
  }

  // ── Profile read ────────────────────────────────────────────────────────────

  /// Fetches the full profile row (nickname, avatar_id, display_name).
  Future<Map<String, dynamic>?> fetchProfile() async {
    if (_uid == null) return null;
    try {
      return await _db
          .from('profiles')
          .select('nickname, avatar_id, display_name')
          .eq('id', _uid!)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  // ── Dashboard stats ─────────────────────────────────────────────────────────

  /// Fetches real stats used by the home-screen dashboard widgets.
  Future<UserStats> fetchStats() async {
    int sessions = 0;
    int groups = 0;
    String vibe = 'hunger';

    if (_uid == null) return UserStats(sessionsCompleted: 0, groupsJoined: 0, totalSavings: 0, favoriteVibe: vibe);

    try {
      // Sessions completed by this user
      final sessionRows = await _db
          .from('sessions')
          .select('id, mode')
          .eq('user_id', _uid!)
          .eq('status', 'completed');
      sessions = sessionRows.length;

      // Count vibe preference
      final hungerCount = sessionRows.where((r) => r['mode'] == 'hunger').length;
      final travelCount = sessionRows.where((r) => r['mode'] == 'travel').length;
      vibe = travelCount > hungerCount ? 'travel' : 'hunger';

      // Groups joined
      final groupRows = await _db
          .from('group_members')
          .select('group_id')
          .eq('user_id', _uid!);
      groups = groupRows.length;
    } catch (_) {
      // Network error or missing table — return safe defaults
    }

    // Gamified total savings: each session saves ~$8.50 (delivery fee saved
    // by making a group decision instead of ordering separately)
    final savings = sessions * 8.50;

    return UserStats(
      sessionsCompleted: sessions,
      groupsJoined: groups,
      totalSavings: savings,
      favoriteVibe: vibe,
    );
  }

  // ── Active session ──────────────────────────────────────────────────────────

  /// Returns the most recent in-progress session for this user, or null.
  Future<Map<String, dynamic>?> fetchActiveSession() async {
    if (_uid == null) return null;
    try {
      return await _db
          .from('sessions')
          .select('id, mode, status')
          .eq('user_id', _uid!)
          .inFilter('status', ['setup', 'swiping'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }
}
