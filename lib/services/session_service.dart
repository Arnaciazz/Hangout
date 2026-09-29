import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place.dart';
import '../screens/session_filters_screen.dart';
import 'places_service.dart';

/// A per-member location entry for a group session lobby.
class SessionLocation {
  final String id;
  final String sessionId;
  final String addedBy;
  final String placeName;
  final double? lat;
  final double? lng;
  final int radiusKm;
  final String addedByDisplayName;

  const SessionLocation({
    required this.id,
    required this.sessionId,
    required this.addedBy,
    required this.placeName,
    this.lat,
    this.lng,
    this.radiusKm = 3,
    this.addedByDisplayName = '',
  });

  factory SessionLocation.fromJson(Map<String, dynamic> json) => SessionLocation(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        addedBy: json['added_by'] as String,
        placeName: json['place_name'] as String? ?? '',
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        radiusKm: json['radius_km'] as int? ?? 3,
        addedByDisplayName:
            (json['profiles'] as Map<String, dynamic>?)?['display_name'] as String? ?? '',
      );
}

/// Summary of a past or active group session.
class SessionSummary {
  final String id;
  final String mode;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;

  const SessionSummary({
    required this.id,
    required this.mode,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) => SessionSummary(
        id: json['id'] as String,
        mode: json['mode'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );
}

/// A lightweight value object returned by [SessionService.createSession].
class SessionModel {
  final String id;
  final String? groupId;
  final String userId;
  final String mode;
  final String type;
  final String status;
  final List<Place> places;

  const SessionModel({
    required this.id,
    this.groupId,
    required this.userId,
    required this.mode,
    required this.type,
    required this.status,
    this.places = const [],
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
        id: json['id'] as String,
        groupId: json['group_id'] as String?,
        userId: json['user_id'] as String,
        mode: json['mode'] as String,
        type: json['type'] as String,
        status: json['status'] as String,
      );

  SessionModel copyWith({String? status, List<Place>? places}) => SessionModel(
        id: id,
        groupId: groupId,
        userId: userId,
        mode: mode,
        type: type,
        status: status ?? this.status,
        places: places ?? this.places,
      );
}

/// Result of a session computation (per place).
class PlaceResult {
  final Place place;
  final int yesVotes;
  final int noVotes;
  final double votePercent;
  final int rank;
  final bool isWinner;

  const PlaceResult({
    required this.place,
    required this.yesVotes,
    required this.noVotes,
    required this.votePercent,
    required this.rank,
    required this.isWinner,
  });
}

class SessionService {
  final SupabaseClient _db = Supabase.instance.client;
  final PlacesService _placesService;

  SessionService({PlacesService? placesService})
      : _placesService = placesService ?? PlacesService();

  // ── Session lifecycle ──────────────────────────────────────────────────────

  /// Create a new session record in Supabase.
  Future<SessionModel> createSession({
    String? groupId,
    required String mode,
    required String type,
  }) async {
    final userId = _db.auth.currentUser!.id;
    debugPrint('[SessionService] createSession: userId=$userId groupId=$groupId mode=$mode type=$type');
    try {
      final row = await _db
          .from('sessions')
          .insert({
            'group_id': groupId,
            'user_id': userId,
            'mode': mode,
            'type': type,
            'status': 'setup',
          })
          .select()
          .single();
      return SessionModel.fromJson(row);
    } catch (e, st) {
      debugPrint('[SessionService] createSession ERROR: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  /// Geocode the given area name, store as a session_location, then fetch
  /// places from Google and persist them in suggested_places.
  /// Returns the session with places populated.
  Future<SessionModel> generatePlaces({
    required SessionModel session,
    required String areaName,
    int radiusMeters = 3000,
    List<String>? includedTypes,
    int? maxPriceLevel,
    bool openNowOnly = false,
  }) async {
    final userId = _db.auth.currentUser!.id;

    // 1. Geocode + fetch nearby
    final result = await _placesService.searchByAddress(
      address: areaName,
      mode: session.mode,
      radiusMeters: radiusMeters,
      includedTypes: includedTypes,
      maxPriceLevel: maxPriceLevel,
      openNowOnly: openNowOnly,
    );

    return _persistPlaces(
      session: session,
      userId: userId,
      lat: result.lat,
      lng: result.lng,
      locationName: areaName,
      places: result.places,
      radiusMeters: radiusMeters,
    );
  }

  /// Fetch places using known lat/lng (from map picker) — skips geocoding.
  Future<SessionModel> generatePlacesByLatLng({
    required SessionModel session,
    required double lat,
    required double lng,
    String locationName = 'Selected location',
    int radiusMeters = 3000,
    List<String>? includedTypes,
    int? maxPriceLevel,
    bool openNowOnly = false,
  }) async {
    final userId = _db.auth.currentUser!.id;

    final places = await _placesService.fetchNearby(
      lat: lat,
      lng: lng,
      mode: session.mode,
      radiusMeters: radiusMeters,
      includedTypes: includedTypes,
      maxPriceLevel: maxPriceLevel,
      openNowOnly: openNowOnly,
    );

    return _persistPlaces(
      session: session,
      userId: userId,
      lat: lat,
      lng: lng,
      locationName: locationName,
      places: places,
      radiusMeters: radiusMeters,
    );
  }

  /// Shared logic: store location + places, update session status.
  Future<SessionModel> _persistPlaces({
    required SessionModel session,
    required String userId,
    required double lat,
    required double lng,
    required String locationName,
    required List<Place> places,
    required int radiusMeters,
  }) async {
    // 1. Store location
    debugPrint('[SessionService] _persistPlaces: session=${session.id} lat=$lat lng=$lng location=$locationName places=${places.length}');
    try {
    await _db.from('session_locations').insert({
      'session_id': session.id,
      'added_by': userId,
      'place_name': locationName,
      'lat': lat,
      'lng': lng,
      'radius_km': (radiusMeters / 1000).round(),
    });

    // 2. Persist places
    if (places.isEmpty) {
      await _db
          .from('sessions')
          .update({'status': 'swiping', 'started_at': DateTime.now().toIso8601String()})
          .eq('id', session.id);
      return session.copyWith(status: 'swiping', places: []);
    }

    final rows = places
        .map((p) => p.toSupabaseJson(session.id))
        .toList();

    final inserted = await _db
        .from('suggested_places')
        .insert(rows)
        .select();

    final savedPlaces = (inserted as List)
        .map((r) => Place.fromSupabaseJson(r as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    // 3. Move session to 'swiping'
    await _db
        .from('sessions')
        .update({'status': 'swiping', 'started_at': DateTime.now().toIso8601String()})
        .eq('id', session.id);

    return session.copyWith(status: 'swiping', places: savedPlaces);
    } catch (e, st) {
      debugPrint('[SessionService] _persistPlaces ERROR: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  /// Load places for an existing session.
  Future<List<Place>> getPlaces(String sessionId) async {
    final rows = await _db
        .from('suggested_places')
        .select()
        .eq('session_id', sessionId)
        .order('display_order');

    return (rows as List)
        .map((r) => Place.fromSupabaseJson(r as Map<String, dynamic>))
        .toList();
  }

  // ── Swipe recording ────────────────────────────────────────────────────────

  /// Record a swipe. [direction] must be 'yes' or 'no'.
  Future<void> recordSwipe({
    required String sessionId,
    required String placeId,
    required String direction,
  }) async {
    final userId = _db.auth.currentUser!.id;

    await _db.from('swipes').upsert({
      'session_id': sessionId,
      'user_id': userId,
      'place_id': placeId,
      'direction': direction,
    }, onConflict: 'session_id,user_id,place_id');
  }

  /// How many places the current user has swiped in a session.
  Future<({int done, int total})> getProgress(String sessionId) async {
    final userId = _db.auth.currentUser!.id;

    final swipesRes = await _db
        .from('swipes')
        .select('id')
        .eq('session_id', sessionId)
        .eq('user_id', userId);

    final totalRes = await _db
        .from('suggested_places')
        .select('id')
        .eq('session_id', sessionId);

    return (done: (swipesRes as List).length, total: (totalRes as List).length);
  }

  // ── Results ────────────────────────────────────────────────────────────────

  /// Compute and persist results, then return ranked list.
  Future<List<PlaceResult>> computeResults(String sessionId) async {
    // Fetch all swipes for this session
    final rows = await _db
        .from('swipes')
        .select('place_id, direction')
        .eq('session_id', sessionId);

    // Tally votes
    final Map<String, int> yesMap = {};
    final Map<String, int> noMap = {};

    for (final r in rows as List) {
      final pid = r['place_id'] as String;
      if (r['direction'] == 'yes') {
        yesMap[pid] = (yesMap[pid] ?? 0) + 1;
      } else {
        noMap[pid] = (noMap[pid] ?? 0) + 1;
      }
    }

    final places = await getPlaces(sessionId);
    if (places.isEmpty) return [];

    // Build results
    final results = places.map((place) {
      final pid = place.id!;
      final yes = yesMap[pid] ?? 0;
      final no = noMap[pid] ?? 0;
      final total = yes + no;
      final pct = total > 0 ? (yes / total * 100) : 0.0;
      return _IntermResult(place: place, yesVotes: yes, noVotes: no, pct: pct);
    }).toList()
      ..sort((a, b) => b.pct.compareTo(a.pct));

    // Persist
    final resultRows = results.asMap().entries.map((e) {
      final i = e.key;
      final r = e.value;
      return {
        'session_id': sessionId,
        'place_id': r.place.id,
        'yes_votes': r.yesVotes,
        'no_votes': r.noVotes,
        'vote_percentage': r.pct,
        'rank': i + 1,
        'is_winner': i == 0 && r.yesVotes > 0,
      };
    }).toList();

    await _db.from('session_results').upsert(resultRows);

    // Update session status
    await _db
        .from('sessions')
        .update({'status': 'revealed', 'completed_at': DateTime.now().toIso8601String()})
        .eq('id', sessionId);

    return results.asMap().entries.map((e) {
      final i = e.key;
      final r = e.value;
      return PlaceResult(
        place: r.place,
        yesVotes: r.yesVotes,
        noVotes: r.noVotes,
        votePercent: r.pct,
        rank: i + 1,
        isWinner: i == 0 && r.yesVotes > 0,
      );
    }).toList();
  }

  // ── Group swipe progress ───────────────────────────────────────────────────

  /// Number of group members who have finished swiping all places.
  Future<({int membersFinished, int totalMembers})> getGroupProgress(
      String sessionId, String groupId) async {
    final members = await _db
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);

    final totalPlaces = await _db
        .from('suggested_places')
        .select('id')
        .eq('session_id', sessionId);
    final placeCount = (totalPlaces as List).length;

    int finished = 0;
    for (final m in members as List) {
      final uid = m['user_id'] as String;
      final swipes = await _db
          .from('swipes')
          .select('id')
          .eq('session_id', sessionId)
          .eq('user_id', uid);
      if ((swipes as List).length >= placeCount) finished++;
    }

    return (membersFinished: finished, totalMembers: (members as List).length);
  }

  /// Realtime stream of group swipe progress.
  /// Emits whenever any swipe row is inserted/updated for this session.
  Stream<({int membersFinished, int totalMembers})> watchGroupProgress(
      String sessionId, String groupId) {
    return _db
        .from('swipes')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .asyncMap((_) => getGroupProgress(sessionId, groupId));
  }

  // ── Group lobby helpers ────────────────────────────────────────────────────

  /// Add (or replace) the current user's location for a group session.
  Future<void> addUserLocation({
    required String sessionId,
    required double lat,
    required double lng,
    String locationName = 'My Location',
    int radiusKm = 3,
  }) async {
    final userId = _db.auth.currentUser!.id;
    // Remove any existing entry for this user in this session.
    await _db
        .from('session_locations')
        .delete()
        .eq('session_id', sessionId)
        .eq('added_by', userId);
    await _db.from('session_locations').insert({
      'session_id': sessionId,
      'added_by': userId,
      'place_name': locationName,
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
    });
  }

  /// Returns all locations that have been submitted for [sessionId],
  /// joined with the submitter's display name from profiles.
  Future<List<SessionLocation>> getSessionLocations(String sessionId) async {
    final rows = await _db
        .from('session_locations')
        .select('*, profiles(display_name)')
        .eq('session_id', sessionId);
    return (rows as List)
        .map((r) => SessionLocation.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Stream that re-fetches session locations whenever the table changes.
  Stream<List<SessionLocation>> watchSessionLocations(String sessionId) {
    return _db
        .from('session_locations')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .asyncMap((_) => getSessionLocations(sessionId));
  }

  /// Returns true if the current user has already added a location.
  Future<bool> hasMyLocation(String sessionId) async {
    final userId = _db.auth.currentUser!.id;
    final rows = await _db
        .from('session_locations')
        .select('id')
        .eq('session_id', sessionId)
        .eq('added_by', userId);
    return (rows as List).isNotEmpty;
  }

  /// Watches the status field of a session and emits on every change.
  Stream<String> watchSessionStatus(String sessionId) {
    return _db
        .from('sessions')
        .stream(primaryKey: ['id'])
        .eq('id', sessionId)
        .map((rows) {
          if ((rows as List).isEmpty) return 'setup';
          return rows.first['status'] as String;
        });
  }

  /// Computes the centroid of all submitted member locations, fetches places,
  /// persists them, and moves the session to 'swiping'.
  Future<SessionModel> startGroupSession({
    required String sessionId,
    required String groupId,
    required String mode,
    required SwipeFilters filters,
  }) async {
    final locations = await getSessionLocations(sessionId);
    final valid = locations.where((l) => l.lat != null && l.lng != null).toList();
    if (valid.isEmpty) throw Exception('No locations have been added yet.');

    final avgLat = valid.map((l) => l.lat!).reduce((a, b) => a + b) / valid.length;
    final avgLng = valid.map((l) => l.lng!).reduce((a, b) => a + b) / valid.length;

    final places = await _placesService.fetchNearby(
      lat: avgLat,
      lng: avgLng,
      mode: mode,
      radiusMeters: filters.radiusMeters,
      includedTypes: filters.placeTypes.isNotEmpty ? filters.placeTypes : null,
      maxPriceLevel: filters.maxPrice,
      openNowOnly: filters.openNowOnly,
    );

    if (places.isEmpty) {
      throw Exception(
          'No ${mode == 'hunger' ? 'restaurants' : 'places'} found near the group. Try adjusting the filters.');
    }

    final rows = places.map((p) => p.toSupabaseJson(sessionId)).toList();
    final inserted = await _db.from('suggested_places').insert(rows).select();
    final savedPlaces = (inserted as List)
        .map((r) => Place.fromSupabaseJson(r as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    await _db
        .from('sessions')
        .update({'status': 'swiping', 'started_at': DateTime.now().toIso8601String()})
        .eq('id', sessionId);

    return SessionModel(
      id: sessionId,
      groupId: groupId,
      userId: _db.auth.currentUser!.id,
      mode: mode,
      type: 'group',
      status: 'swiping',
      places: savedPlaces,
    );
  }

  /// Load a session from DB and populate its places.
  Future<SessionModel> getSessionWithPlaces(String sessionId) async {
    final row = await _db.from('sessions').select().eq('id', sessionId).single();
    final session = SessionModel.fromJson(row);
    final places = await getPlaces(sessionId);
    return session.copyWith(places: places);
  }

  /// Active (setup/swiping/revealed) sessions for a group, newest first.
  Future<List<SessionSummary>> getActiveSessions(String groupId) async {
    final rows = await _db
        .from('sessions')
        .select('id, mode, status, created_at, completed_at')
        .eq('group_id', groupId)
        .inFilter('status', ['setup', 'swiping', 'revealed'])
        .order('created_at', ascending: false)
        .limit(1);
    return (rows as List)
        .map((r) => SessionSummary.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Past (completed) sessions for a group, newest first.
  Future<List<SessionSummary>> getPastSessions(String groupId) async {
    final rows = await _db
        .from('sessions')
        .select('id, mode, status, created_at, completed_at')
        .eq('group_id', groupId)
        .eq('status', 'completed')
        .order('created_at', ascending: false)
        .limit(10);
    return (rows as List)
        .map((r) => SessionSummary.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Check if the current user has finished swiping all places in [sessionId].
  Future<bool> hasCurrentUserFinished(String sessionId) async {
    final userId = _db.auth.currentUser!.id;
    final swipes = await _db
        .from('swipes')
        .select('id')
        .eq('session_id', sessionId)
        .eq('user_id', userId);
    final places = await _db
        .from('suggested_places')
        .select('id')
        .eq('session_id', sessionId);
    return (swipes as List).length >= (places as List).length;
  }
}

class _IntermResult {
  final Place place;
  final int yesVotes;
  final int noVotes;
  final double pct;
  const _IntermResult({
    required this.place,
    required this.yesVotes,
    required this.noVotes,
    required this.pct,
  });
}
