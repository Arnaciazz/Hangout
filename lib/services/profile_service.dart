import 'package:supabase_flutter/supabase_flutter.dart';

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
}
