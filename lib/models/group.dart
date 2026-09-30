class GroupMember {
  final String userId;
  final String groupId;
  final String role; // 'owner' | 'member'
  final String displayName;
  final String? avatarUrl;
  final DateTime joinedAt;

  const GroupMember({
    required this.userId,
    required this.groupId,
    required this.role,
    required this.displayName,
    this.avatarUrl,
    required this.joinedAt,
  });

  bool get isOwner => role == 'owner';

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final profile = (json['profiles'] as Map<String, dynamic>?) ?? {};
    return GroupMember(
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      displayName: profile['display_name'] as String? ?? 'User',
      avatarUrl: profile['avatar_url'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

class Group {
  final String id;
  final String name;
  final String mode; // 'hunger' | 'travel'
  final String createdBy;
  final String inviteCode;
  final DateTime createdAt;
  final List<GroupMember> members;

  const Group({
    required this.id,
    required this.name,
    required this.mode,
    required this.createdBy,
    required this.inviteCode,
    required this.createdAt,
    this.members = const [],
  });

  bool isOwner(String userId) => createdBy == userId;
  int get memberCount => members.length;

  factory Group.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['group_members'] as List<dynamic>? ?? [];
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      mode: json['mode'] as String,
      createdBy: json['created_by'] as String,
      inviteCode: json['invite_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      members: rawMembers
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
