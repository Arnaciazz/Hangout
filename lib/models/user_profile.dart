class UserProfile {
  final String name;
  final String title;
  final String membershipTier;
  final int decisionsCount;
  final int streakDays;
  final int friendsCount;
  final double totalSpent;

  const UserProfile({
    required this.name,
    required this.title,
    required this.membershipTier,
    required this.decisionsCount,
    required this.streakDays,
    required this.friendsCount,
    required this.totalSpent,
  });
}

class SampleUser {
  static const UserProfile alex = UserProfile(
    name: 'Alex Chen',
    title: 'Decision Master',
    membershipTier: 'Premium',
    decisionsCount: 142,
    streakDays: 23,
    friendsCount: 38,
    totalSpent: 2847.50,
  );
}
