import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';

class GroupService {
  final _db = Supabase.instance.client;

  String get _userId => _db.auth.currentUser!.id;

  // ─── Ensure user profile exists ───────────────────────────────────────────

  Future<void> _ensureProfile() async {
    try {
      final user = _db.auth.currentUser!;
      final meta = user.userMetadata ?? {};
      final name = (meta['full_name'] as String?) ??
          (meta['name'] as String?) ??
          user.email ??
          'User';
      await _db.from('profiles').upsert({
        'id': user.id,
        'display_name': name,
        'avatar_url': meta['avatar_url'],
      }, onConflict: 'id');
    } catch (_) {
      // Profile might already exist — continue regardless
    }
  }

  // ─── Invite code generation ───────────────────────────────────────────────

  static String generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ─── Fetch helpers ────────────────────────────────────────────────────────

  Future<List<Group>> getMyGroups() async {
    // Step 1: get group IDs where current user is a member
    final memberRows = await _db
        .from('group_members')
        .select('group_id')
        .eq('user_id', _userId);

    final groupIds = (memberRows as List)
        .map((r) => r['group_id'] as String)
        .toList();

    if (groupIds.isEmpty) return [];

    // Step 2: fetch those groups with nested members + profiles
    final rows = await _db
        .from('groups')
        .select('*, group_members(user_id, group_id, role, joined_at, profiles(display_name, avatar_url))')
        .inFilter('id', groupIds)
        .order('created_at', ascending: false);

    return (rows as List).map((j) => Group.fromJson(j as Map<String, dynamic>)).toList();
  }

  // Realtime-ish stream: re-fetches groups when group_members table changes
  Stream<List<Group>> watchMyGroups() {
    return _db
        .from('group_members')
        .stream(primaryKey: ['group_id', 'user_id'])
        .eq('user_id', _userId)
        .asyncMap((_) => getMyGroups());
  }

  Future<Group?> getGroupDetails(String groupId) async {
    final row = await _db
        .from('groups')
        .select('*, group_members(user_id, group_id, role, joined_at, profiles(display_name, avatar_url))')
        .eq('id', groupId)
        .single();
    return Group.fromJson(row as Map<String, dynamic>);
  }

  // ─── Create group ─────────────────────────────────────────────────────────

  Future<Group> createGroup(String name, String mode) async {
    await _ensureProfile();
    debugPrint('[GroupService] createGroup: name=$name mode=$mode userId=$_userId');
    try {
      final code = generateCode();

      final groupRow = await _db.from('groups').insert({
        'name': name.trim(),
        'mode': mode,
        'created_by': _userId,
        'invite_code': code,
      }).select().single();

      final groupId = groupRow['id'] as String;
      debugPrint('[GroupService] group created: $groupId, inserting member...');

      // Add creator as owner
      await _db.from('group_members').insert({
        'group_id': groupId,
        'user_id': _userId,
        'role': 'owner',
      });

      final group = await getGroupDetails(groupId);
      return group!;
    } catch (e, st) {
      debugPrint('[GroupService] createGroup ERROR: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  // ─── Join by code ─────────────────────────────────────────────────────────

  Future<JoinResult> joinByCode(String code) async {
    await _ensureProfile();
    final rows = await _db
        .from('groups')
        .select('id, name')
        .eq('invite_code', code.toUpperCase().trim())
        .limit(1);

    if ((rows as List).isEmpty) {
      return JoinResult.notFound();
    }

    final groupId = rows[0]['id'] as String;
    final groupName = rows[0]['name'] as String;

    // Check if already a member
    final existing = await _db
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId)
        .eq('user_id', _userId)
        .limit(1);

    if ((existing as List).isNotEmpty) {
      return JoinResult.alreadyMember(groupId, groupName);
    }

    // Check group size limit (max 10)
    final members = await _db
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);

    if ((members as List).length >= 10) {
      return JoinResult.full(groupName);
    }

    await _db.from('group_members').insert({
      'group_id': groupId,
      'user_id': _userId,
      'role': 'member',
    });

    return JoinResult.success(groupId, groupName);
  }

  // ─── Leave group ──────────────────────────────────────────────────────────

  Future<void> leaveGroup(String groupId) async {
    await _db
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', _userId);
  }

  // ─── Delete group (owner only) ────────────────────────────────────────────

  Future<void> deleteGroup(String groupId) async {
    final result = await _db
        .from('groups')
        .delete()
        .eq('id', groupId)
        .eq('created_by', _userId)
        .select('id');
    if ((result as List).isEmpty) {
      throw Exception(
        'Could not delete group. Make sure you are the creator and the RLS DELETE policy exists on the groups table.',
      );
    }
  }

  // ─── Refresh invite code (owner only) ────────────────────────────────────

  Future<String> refreshInviteCode(String groupId) async {
    final newCode = generateCode();
    await _db
        .from('groups')
        .update({'invite_code': newCode})
        .eq('id', groupId)
        .eq('created_by', _userId);
    return newCode;
  }
}

// ─── Result types ─────────────────────────────────────────────────────────────

enum JoinResultType { success, alreadyMember, notFound, full }

class JoinResult {
  final JoinResultType type;
  final String? groupId;
  final String? groupName;
  final String? errorMessage;

  JoinResult._({
    required this.type,
    this.groupId,
    this.groupName,
    this.errorMessage,
  });

  bool get success =>
      type == JoinResultType.success || type == JoinResultType.alreadyMember;

  factory JoinResult.success(String id, String name) => JoinResult._(
        type: JoinResultType.success,
        groupId: id,
        groupName: name,
      );

  factory JoinResult.alreadyMember(String id, String name) => JoinResult._(
        type: JoinResultType.alreadyMember,
        groupId: id,
        groupName: name,
      );

  factory JoinResult.notFound() => JoinResult._(
        type: JoinResultType.notFound,
        errorMessage: 'No group found with that code. Check and try again.',
      );

  factory JoinResult.full(String name) => JoinResult._(
        type: JoinResultType.full,
        errorMessage: '"$name" is full (max 10 members).',
      );
}
