import '../config/app_config.dart';

class PlacePhoto {
  final String name; // Google resource name, e.g. "places/ChI.../photos/AX..."

  const PlacePhoto({required this.name});

  /// Direct URL Flutter Image.network can load (redirect handled automatically).
  String get url =>
      'https://places.googleapis.com/v1/$name/media?maxWidthPx=800&key=${AppConfig.googleApiKey}';

  factory PlacePhoto.fromJson(Map<String, dynamic> json) =>
      PlacePhoto(name: json['name'] as String);

  Map<String, dynamic> toJson() => {'name': name};
}

class PlaceReview {
  final String text;
  final double? rating;
  final String authorName;
  final String? relativeTime;

  const PlaceReview({
    required this.text,
    required this.rating,
    required this.authorName,
    this.relativeTime,
  });

  factory PlaceReview.fromGoogleJson(Map<String, dynamic> json) {
    final textObj = json['text'] as Map<String, dynamic>?;
    final author = json['authorAttribution'] as Map<String, dynamic>?;
    return PlaceReview(
      text: textObj?['text'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble(),
      authorName: author?['displayName'] as String? ?? 'Anonymous',
      relativeTime: json['relativePublishTimeDescription'] as String?,
    );
  }

  factory PlaceReview.fromJson(Map<String, dynamic> json) => PlaceReview(
        text: json['text'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble(),
        authorName: json['authorName'] as String? ?? 'Anonymous',
        relativeTime: json['relativeTime'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'rating': rating,
        'authorName': authorName,
        'relativeTime': relativeTime,
      };
}

int _parsePriceLevel(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  // New Places API returns enum strings
  const map = {
    'PRICE_LEVEL_FREE': 0,
    'PRICE_LEVEL_INEXPENSIVE': 1,
    'PRICE_LEVEL_MODERATE': 2,
    'PRICE_LEVEL_EXPENSIVE': 3,
    'PRICE_LEVEL_VERY_EXPENSIVE': 4,
  };
  return map[value as String] ?? 0;
}

class Place {
  final String? id; // Supabase UUID, null before saved
  final String googlePlaceId;
  final String name;
  final String? address;
  final double? lat;
  final double? lng;
  final double? rating;
  final int? ratingCount;
  final int? priceLevel; // 0-4
  final bool? isOpenNow;
  final String? phone;
  final String? websiteUrl;
  final String? googleMapsUri;
  final List<PlacePhoto> photos;
  final List<PlaceReview> reviews;
  final String? cuisineType;
  final int displayOrder;

  const Place({
    this.id,
    required this.googlePlaceId,
    required this.name,
    this.address,
    this.lat,
    this.lng,
    this.rating,
    this.ratingCount,
    this.priceLevel,
    this.isOpenNow,
    this.phone,
    this.websiteUrl,
    this.googleMapsUri,
    this.photos = const [],
    this.reviews = const [],
    this.cuisineType,
    this.displayOrder = 0,
  });

  // ── Derived ────────────────────────────────────────────────────────────────

  String get priceDisplay {
    if (priceLevel == null || priceLevel == 0) return '';
    return '₹' * priceLevel!;
  }

  String get mainPhotoUrl => photos.isNotEmpty ? photos.first.url : '';

  String get openStatusDisplay =>
      isOpenNow == null ? '' : (isOpenNow! ? 'Open now' : 'Closed');

  String get ratingDisplay =>
      rating != null ? rating!.toStringAsFixed(1) : '—';

  String get reviewCount =>
      ratingCount != null ? '(${_formatCount(ratingCount!)})' : '';

  String get dineoutUrl {
    final city = _extractCity(address ?? '');
    final q = Uri.encodeComponent('${name.toLowerCase()} $city');
    return 'https://www.dineout.co.in/search?q=$q';
  }

  String get eazyDinerUrl {
    final city = _extractCity(address ?? '');
    final q = Uri.encodeComponent('$name $city');
    return 'https://www.eazydiner.com/search?q=$q';
  }

  // ── Factories ──────────────────────────────────────────────────────────────

  factory Place.fromGoogleJson(Map<String, dynamic> json, int order) {
    final displayName = json['displayName'] as Map<String, dynamic>?;
    final primaryType = json['primaryTypeDisplayName'] as Map<String, dynamic>?;
    final openingHours = json['regularOpeningHours'] as Map<String, dynamic>?;

    final photos = (json['photos'] as List<dynamic>?)
            ?.map((p) => PlacePhoto.fromJson(p as Map<String, dynamic>))
            .take(10)
            .toList() ??
        [];

    final reviews = (json['reviews'] as List<dynamic>?)
            ?.map((r) => PlaceReview.fromGoogleJson(r as Map<String, dynamic>))
            .take(5)
            .toList() ??
        [];

    return Place(
      googlePlaceId: json['id'] as String? ?? '',
      name: displayName?['text'] as String? ?? 'Unknown',
      address: json['formattedAddress'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['userRatingCount'] as int?,
      priceLevel: _parsePriceLevel(json['priceLevel']),
      isOpenNow: openingHours?['openNow'] as bool?,
      phone: json['nationalPhoneNumber'] as String?,
      websiteUrl: json['websiteUri'] as String?,
      googleMapsUri: json['googleMapsUri'] as String?,
      photos: photos,
      reviews: reviews,
      cuisineType: primaryType?['text'] as String?,
      displayOrder: order,
    );
  }

  /// For saving to Supabase suggested_places table.
  Map<String, dynamic> toSupabaseJson(String sessionId) => {
        'session_id': sessionId,
        'google_place_id': googlePlaceId,
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'rating': rating,
        'rating_count': ratingCount,
        'price_level': priceLevel,
        'is_open_now': isOpenNow,
        'phone': phone,
        'website_url': websiteUrl,
        'google_maps_uri': googleMapsUri,
        'dineout_url': dineoutUrl,
        'eazydiner_url': eazyDinerUrl,
        'photos': photos.map((p) => p.toJson()).toList(),
        'reviews': reviews.map((r) => r.toJson()).toList(),
        'cuisine_type': cuisineType,
        'display_order': displayOrder,
      };

  factory Place.fromSupabaseJson(Map<String, dynamic> json) {
    final photosList = (json['photos'] as List<dynamic>?)
            ?.map((p) => PlacePhoto.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];
    final reviewsList = (json['reviews'] as List<dynamic>?)
            ?.map((r) => PlaceReview.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return Place(
      id: json['id'] as String?,
      googlePlaceId: json['google_place_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      address: json['address'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['rating_count'] as int?,
      priceLevel: json['price_level'] as int?,
      isOpenNow: json['is_open_now'] as bool?,
      phone: json['phone'] as String?,
      websiteUrl: json['website_url'] as String?,
      googleMapsUri: json['google_maps_uri'] as String?,
      photos: photosList,
      reviews: reviewsList,
      cuisineType: json['cuisine_type'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  static String _extractCity(String address) {
    // Simple heuristic: take the 2nd-to-last comma-separated token as city
    final parts = address.split(',');
    if (parts.length >= 2) {
      return parts[parts.length - 2].trim();
    }
    return '';
  }
}
