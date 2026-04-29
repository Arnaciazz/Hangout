class Memory {
  final String title;
  final String date;
  final String location;
  final String emoji;
  final List<String> tags;
  final int photoCount;
  final double spent;

  const Memory({
    required this.title,
    required this.date,
    required this.location,
    required this.emoji,
    this.tags = const [],
    this.photoCount = 0,
    this.spent = 0,
  });
}

class SampleMemories {
  static const List<Memory> all = [
    Memory(
      title: 'Neon Lotus Night',
      date: 'Oct 12',
      location: 'Shinjuku',
      emoji: '🏮',
      tags: ['Asian Fusion', 'Cocktails', 'Group'],
      photoCount: 24,
      spent: 186.50,
    ),
    Memory(
      title: 'Omakase Nights',
      date: 'Oct 10',
      location: 'Roppongi',
      emoji: '🍣',
      tags: ['Japanese', 'Fine Dining', 'Date Night'],
      photoCount: 12,
      spent: 245.00,
    ),
    Memory(
      title: 'Neon Sips',
      date: 'Oct 09',
      location: 'Shibuya',
      emoji: '🍸',
      tags: ['Cocktails', 'Nightlife', 'Dancing'],
      photoCount: 37,
      spent: 98.00,
    ),
    Memory(
      title: 'Morning Brew',
      date: 'Oct 08',
      location: 'Daikanyama',
      emoji: '☕',
      tags: ['Coffee', 'Brunch', 'Chill'],
      photoCount: 8,
      spent: 32.00,
    ),
    Memory(
      title: 'Ramen Quest',
      date: 'Oct 05',
      location: 'Ikebukuro',
      emoji: '🍜',
      tags: ['Ramen', 'Late Night', 'Adventure'],
      photoCount: 15,
      spent: 42.00,
    ),
  ];
}
