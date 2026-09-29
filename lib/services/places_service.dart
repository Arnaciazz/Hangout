import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/place.dart';

class PlacesServiceException implements Exception {
  final String message;
  const PlacesServiceException(this.message);
  @override
  String toString() => 'PlacesServiceException: $message';
}

class PlacesService {
  final http.Client _client;

  PlacesService({http.Client? client}) : _client = client ?? http.Client();

  static const _geocodeBase = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const _fieldMask =
      'places.id,'
      'places.displayName,'
      'places.formattedAddress,'
      'places.rating,'
      'places.userRatingCount,'
      'places.priceLevel,'
      'places.regularOpeningHours,'
      'places.nationalPhoneNumber,'
      'places.websiteUri,'
      'places.googleMapsUri,'
      'places.primaryTypeDisplayName,'
      'places.photos,'
      'places.reviews';

  static const _includedTypesHunger = ['restaurant', 'cafe', 'bar'];
  static const _includedTypesTravel = [
    'tourist_attraction',
    'museum',
    'amusement_park',
    'park',
    'art_gallery',
    'historical_landmark',
    'shopping_mall',
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Geocode a text address to lat/lng coordinates.
  Future<({double lat, double lng})> geocodeAddress(String address) async {
    final uri = Uri.parse(_geocodeBase).replace(queryParameters: {
      'address': address,
      'key': AppConfig.googleApiKey,
      'region': 'in',
      'language': 'en',
    });

    final response = await _client.get(uri);
    _assertStatus(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String;
    if (status != 'OK') {
      throw PlacesServiceException(
        'Geocoding failed ($status) for "$address". Try a more specific location.',
      );
    }

    final loc =
        (body['results'] as List).first['geometry']['location'] as Map<String, dynamic>;
    return (lat: (loc['lat'] as num).toDouble(), lng: (loc['lng'] as num).toDouble());
  }

  /// Fetch nearby places for a session based on mode and location.
  /// Returns parsed [Place] list (not yet saved to Supabase).
  Future<List<Place>> fetchNearby({
    required double lat,
    required double lng,
    required String mode, // 'hunger' | 'travel'
    int radiusMeters = 3000,
    int maxResults = 10,
    List<String>? includedTypes, // override default types for the mode
    int? maxPriceLevel,          // 1-4; null = any
    bool openNowOnly = false,
  }) async {
    final types = includedTypes != null && includedTypes.isNotEmpty
        ? includedTypes
        : (mode == 'hunger' ? _includedTypesHunger : _includedTypesTravel);

    final uri = Uri.parse('${AppConfig.placesBaseUrl}/places:searchNearby');

    final body = <String, dynamic>{
      'locationRestriction': {
        'circle': {
          'center': {'latitude': lat, 'longitude': lng},
          'radius': radiusMeters.toDouble(),
        },
      },
      'includedTypes': types,
      'maxResultCount': maxResults,
      'rankPreference': 'POPULARITY',
      'languageCode': 'en',
      'regionCode': 'IN',
    };

    // NOTE: priceLevels is NOT supported by searchNearby — filter client-side below.

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': AppConfig.googleApiKey,
        'X-Goog-FieldMask': _fieldMask,
      },
      body: jsonEncode(body),
    );

    _assertStatus(response);

    final resBody = jsonDecode(response.body) as Map<String, dynamic>;
    final rawPlaces = (resBody['places'] as List<dynamic>?) ?? [];

    var places = rawPlaces
        .asMap()
        .entries
        .map((e) => Place.fromGoogleJson(e.value as Map<String, dynamic>, e.key))
        .toList();

    // Client-side filters
    if (maxPriceLevel != null) {
      // Keep places with a known price within budget, or unknown price (null)
      places = places
          .where((p) => p.priceLevel == null || p.priceLevel! <= maxPriceLevel)
          .toList();
    }
    if (openNowOnly) {
      places = places.where((p) => p.isOpenNow == true).toList();
    }

    return places;
  }

  /// Convenience: geocode then fetch nearby.
  Future<({List<Place> places, double lat, double lng})> searchByAddress({
    required String address,
    required String mode,
    int radiusMeters = 3000,
    List<String>? includedTypes,
    int? maxPriceLevel,
    bool openNowOnly = false,
  }) async {
    final coords = await geocodeAddress(address);
    final places = await fetchNearby(
      lat: coords.lat,
      lng: coords.lng,
      mode: mode,
      radiusMeters: radiusMeters,
      includedTypes: includedTypes,
      maxPriceLevel: maxPriceLevel,
      openNowOnly: openNowOnly,
    );
    return (places: places, lat: coords.lat, lng: coords.lng);
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _assertStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlacesServiceException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}\n${response.body}',
      );
    }
  }
}
