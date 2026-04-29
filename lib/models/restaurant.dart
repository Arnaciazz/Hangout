class Restaurant {
  final String name;
  final String subtitle;
  final String imageUrl;
  final double rating;
  final String priceRange;
  final List<String> vibes;
  final List<MenuItem> menu;
  final List<Review> reviews;
  final String distance;
  final String cuisine;
  final bool isMatch;

  const Restaurant({
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    required this.rating,
    required this.priceRange,
    required this.vibes,
    required this.menu,
    required this.reviews,
    this.distance = '0.3 mi',
    this.cuisine = 'Asian Fusion',
    this.isMatch = false,
  });
}

class MenuItem {
  final String name;
  final double price;
  final String emoji;

  const MenuItem({
    required this.name,
    required this.price,
    required this.emoji,
  });
}

class Review {
  final String name;
  final String badge;
  final String text;
  final double rating;

  const Review({
    required this.name,
    required this.badge,
    required this.text,
    required this.rating,
  });
}

// === Sample Data ===
class SampleRestaurants {
  static const List<Restaurant> all = [
    Restaurant(
      name: 'Neon Lotus',
      subtitle: 'Modern Asian Fusion & Craft Cocktails',
      imageUrl: 'neon_lotus',
      rating: 4.8,
      priceRange: '\$\$\$',
      distance: '0.3 mi',
      cuisine: 'Asian Fusion',
      vibes: ['🔥 Trendy', '🎶 Live DJ', '🍸 Cocktails', '📸 Instagrammable'],
      menu: [
        MenuItem(name: 'Dragon Roll', price: 24, emoji: '🐉'),
        MenuItem(name: 'Smoked Negroni', price: 18, emoji: '🥃'),
        MenuItem(name: 'Crispy Rice', price: 16, emoji: '🍚'),
        MenuItem(name: 'Wagyu Tataki', price: 32, emoji: '🥩'),
      ],
      reviews: [
        Review(
          name: 'Sarah J.',
          badge: 'Local Guide',
          text: 'Absolutely electric atmosphere. The smoked negroni is a must-try, and the DJ perfectly matched the energy of the room. Perfect spot for a Friday night out.',
          rating: 5.0,
        ),
        Review(
          name: 'Michael T.',
          badge: 'Foodie',
          text: 'The sushi rolls are incredibly fresh. A bit loud, but that\'s the vibe. Service was remarkably fast.',
          rating: 4.5,
        ),
      ],
    ),
    Restaurant(
      name: 'Sakura Sushi Bar',
      subtitle: 'Traditional Japanese · Omakase',
      imageUrl: 'sakura',
      rating: 4.8,
      priceRange: '\$\$\$\$',
      distance: '0.5 mi',
      cuisine: 'Japanese',
      isMatch: true,
      vibes: ['🍣 Authentic', '🎋 Zen', '🍶 Sake Bar', '✨ Intimate'],
      menu: [
        MenuItem(name: 'Omakase Set', price: 85, emoji: '🍣'),
        MenuItem(name: 'Sake Flight', price: 28, emoji: '🍶'),
        MenuItem(name: 'Uni Sashimi', price: 36, emoji: '🦐'),
      ],
      reviews: [
        Review(
          name: 'Emily R.',
          badge: 'Top Reviewer',
          text: 'Best omakase outside of Japan. Chef Tanaka is a true artist.',
          rating: 5.0,
        ),
      ],
    ),
    Restaurant(
      name: 'Le Petit Bistro',
      subtitle: 'Classic French · Wine Bar',
      imageUrl: 'bistro',
      rating: 4.5,
      priceRange: '\$\$\$',
      distance: '0.8 mi',
      cuisine: 'French',
      isMatch: true,
      vibes: ['🍷 Romantic', '🕯️ Cozy', '🧀 Charcuterie', '🌹 Date Night'],
      menu: [
        MenuItem(name: 'Coq au Vin', price: 28, emoji: '🍗'),
        MenuItem(name: 'Crème Brûlée', price: 14, emoji: '🍮'),
        MenuItem(name: 'Wine Pairing', price: 22, emoji: '🍷'),
      ],
      reviews: [
        Review(
          name: 'David L.',
          badge: 'Wine Expert',
          text: 'Exceptional wine list and the coq au vin is divine.',
          rating: 4.5,
        ),
      ],
    ),
    Restaurant(
      name: 'Morning Brew',
      subtitle: 'Specialty Coffee & Artisan Pastries',
      imageUrl: 'brew',
      rating: 4.9,
      priceRange: '\$\$',
      distance: '0.1 mi',
      cuisine: 'Café',
      isMatch: true,
      vibes: ['☕ Chill', '📖 Work-Friendly', '🥐 Pastries', '🌿 Plants'],
      menu: [
        MenuItem(name: 'Pour Over', price: 6, emoji: '☕'),
        MenuItem(name: 'Matcha Latte', price: 7, emoji: '🍵'),
        MenuItem(name: 'Croissant', price: 5, emoji: '🥐'),
      ],
      reviews: [
        Review(
          name: 'Anna K.',
          badge: 'Regular',
          text: 'My daily sanctuary. Best pour over in the city.',
          rating: 5.0,
        ),
      ],
    ),
  ];
}
