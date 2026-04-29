class Session {
  final String title;
  final String subtitle;
  final int participants;
  final int votesIn;
  final int totalVotes;
  final Duration timeRemaining;
  final SessionStatus status;

  const Session({
    required this.title,
    required this.subtitle,
    required this.participants,
    required this.votesIn,
    required this.totalVotes,
    required this.timeRemaining,
    required this.status,
  });

  double get progress => votesIn / totalVotes;
}

enum SessionStatus { active, waiting, completed }

class SampleSessions {
  static const List<Session> all = [
    Session(
      title: 'Finding Dinner Spots',
      subtitle: 'Friday night crew',
      participants: 5,
      votesIn: 3,
      totalVotes: 5,
      timeRemaining: Duration(minutes: 12, seconds: 34),
      status: SessionStatus.active,
    ),
    Session(
      title: 'Weekend Getaway',
      subtitle: 'Adventure squad',
      participants: 4,
      votesIn: 1,
      totalVotes: 4,
      timeRemaining: Duration(hours: 2, minutes: 45),
      status: SessionStatus.waiting,
    ),
  ];
}
