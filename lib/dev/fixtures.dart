// Illustrative fixture data for the design gallery and preview renders.
//
// Nothing here is real: every name is an obvious placeholder ("Example …",
// "Friend 1"), and nothing in the app imports this file — only
// lib/design_gallery.dart and the tests do.

import '../models/group.dart';
import '../models/place.dart';
import '../services/history_service.dart';
import '../services/session_service.dart';

const _photo = PlacePhoto(name: 'places/fixture/photos/1');

/// A place. [withPhoto] is off for the gallery, where a fixture photo would
/// only produce a failed Places API request.
Place fixturePlace(
  String name, {
  double rating = 4.4,
  bool withPhoto = true,
  List<PlaceReview> reviews = const [],
}) =>
    Place(
      id: name,
      googlePlaceId: name,
      name: name,
      address: '14 Example Road, Banjara Hills',
      rating: rating,
      ratingCount: 1280,
      priceLevel: 2,
      isOpenNow: true,
      cuisineType: 'Hyderabadi',
      photos: withPhoto ? const [_photo] : const [],
      reviews: reviews,
    );

HangoutMemory fixtureMemory(
  String name,
  String? crew,
  DateTime date, {
  bool withPhoto = true,
}) =>
    HangoutMemory(
      sessionId: name,
      mode: 'hunger',
      groupName: crew,
      date: date,
      winner: fixturePlace(name, withPhoto: withPhoto),
      yesVotes: 4,
      noVotes: 1,
    );

Group fixtureCrew(String name, String mode, int people) => Group(
      id: name,
      name: name,
      mode: mode,
      createdBy: 'u0',
      inviteCode: 'K7QX2M',
      createdAt: DateTime(2026, 9, 1),
      members: [
        for (var i = 0; i < people; i++)
          GroupMember(
            userId: 'u$i',
            groupId: name,
            role: i == 0 ? 'owner' : 'member',
            displayName: 'Friend ${i + 1}',
            joinedAt: DateTime(2026, 9, 1),
          ),
      ],
    );

List<Group> fixtureCrews() => [
      fixtureCrew('Friday dinner lot', 'hunger', 5),
      fixtureCrew('Office lunch', 'hunger', 8),
      fixtureCrew('Weekend wanderers', 'travel', 3),
    ];

List<HangoutMemory> fixtureMemories(DateTime today, {bool withPhoto = true}) => [
      fixtureMemory('Example Biryani House', 'Friday dinner lot',
          today.subtract(const Duration(days: 1)), withPhoto: withPhoto),
      fixtureMemory('Example Café', 'Office lunch',
          today.subtract(const Duration(days: 4)), withPhoto: withPhoto),
      fixtureMemory('Example Dhaba', null,
          today.subtract(const Duration(days: 12)), withPhoto: withPhoto),
    ];

const fixtureActive = ActiveHangout(
  sessionId: 's1',
  mode: 'hunger',
  status: 'swiping',
  groupId: 'g1',
  groupName: 'Friday dinner lot',
);

SessionModel fixtureSwipeSession({bool withPhoto = true}) => SessionModel(
      id: 's1',
      userId: 'u0',
      mode: 'hunger',
      type: 'solo',
      status: 'swiping',
      places: [
        fixturePlace('Example Biryani House',
            rating: 4.6,
            withPhoto: withPhoto,
            reviews: const [
              PlaceReview(
                text: 'Illustrative review text, for layout only.',
                rating: 5,
                authorName: 'Example Reviewer',
                relativeTime: 'a week ago',
              ),
            ]),
        fixturePlace('Example Café', withPhoto: withPhoto),
        fixturePlace('Example Dhaba', withPhoto: withPhoto),
      ],
    );

const fixtureRevealedSession = SessionModel(
  id: 's1',
  userId: 'u0',
  mode: 'hunger',
  type: 'group',
  status: 'revealed',
);

List<PlaceResult> fixtureResults({bool withPhoto = true}) {
  PlaceResult r(String name, int rank, int yes, int no) => PlaceResult(
        place: fixturePlace(name, withPhoto: withPhoto),
        yesVotes: yes,
        noVotes: no,
        votePercent: yes / (yes + no) * 100,
        rank: rank,
        isWinner: rank == 1,
      );
  return [
    r('Example Biryani House', 1, 4, 1),
    r('Example Café', 2, 3, 2),
    r('Example Dhaba', 3, 1, 4),
  ];
}
