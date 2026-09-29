import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle/models/place.dart';
import 'package:shuffle/screens/memory_screen.dart';
import 'package:shuffle/screens/profile_screen.dart';
import 'package:shuffle/screens/session_filters_screen.dart';
import 'package:shuffle/services/history_service.dart';
import 'package:shuffle/theme/app_theme.dart';
import 'package:shuffle/widgets/bottom_nav_bar.dart';
import 'package:shuffle/widgets/hangout_avatar.dart';
import 'package:shuffle/widgets/hangout_button.dart';
import 'package:shuffle/widgets/hangout_card.dart';
import 'package:shuffle/widgets/hangout_chips.dart';
import 'package:shuffle/widgets/hangout_list.dart';

// Layout regression tests.
//
// A RenderFlex overflow, a negative Container margin, or any other layout
// assertion surfaces as an exception during pump, which `takeException`
// returns. Every test asserts the frame rendered cleanly — that catches the
// "overflowed by N pixels" class of bug without a device.

const _phone = Size(390, 844);
const _small = Size(320, 640); // smallest phone we care about

void _setSurface(WidgetTester tester, Size size, {double textScale = 1.0}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.lightTheme, home: home);

Future<void> _expectClean(WidgetTester tester) async {
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

// Fixture data. Place names are illustrative, not real venues.
HangoutMemory _memory(String name, {String? crew, int days = 0, int yes = 4, int no = 1}) =>
    HangoutMemory(
      sessionId: name,
      mode: 'hunger',
      groupName: crew,
      date: DateTime.now().subtract(Duration(days: days)),
      winner: Place(googlePlaceId: name, name: name, rating: 4.5, address: '12 Example Road'),
      yesVotes: yes,
      noVotes: no,
    );

void main() {
  group('AvatarGroup', () {
    // Regression: overlapping avatars once used negative Container margins,
    // which trips `margin.isNonNegative`.
    for (final count in [1, 2, 4, 7]) {
      testWidgets('renders $count people', (tester) async {
        _setSurface(tester, _phone);
        await tester.pumpWidget(_app(Scaffold(
          body: Center(
            child: AvatarGroup(
              people: List.generate(count, (i) => (name: 'Person $i', imageUrl: null)),
            ),
          ),
        )));
        await _expectClean(tester);
      });
    }

    testWidgets('shows a +N chip past the max', (tester) async {
      _setSurface(tester, _phone);
      await tester.pumpWidget(_app(Scaffold(
        body: Center(
          child: AvatarGroup(
            max: 3,
            people: List.generate(7, (i) => (name: 'Person $i', imageUrl: null)),
          ),
        ),
      )));
      await _expectClean(tester);
      expect(find.text('+4'), findsOneWidget);
    });
  });

  group('PlaceCard', () {
    // Regression: the card's natural height exceeded its rail. It must yield
    // photo height rather than overflow.
    for (final railHeight in [274.0, 200.0]) {
      testWidgets('fits a ${railHeight.toInt()}px rail', (tester) async {
        _setSurface(tester, _phone);
        await tester.pumpWidget(_app(Scaffold(
          body: SizedBox(
            height: railHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                PlaceCard(
                  width: 210,
                  title: 'Example Bistro',
                  location: 'Somewhere central',
                  rating: 4.5,
                  tags: ['French', 'Wine'],
                ),
              ],
            ),
          ),
        )));
        await _expectClean(tester);
      });
    }
  });

  group('Components', () {
    testWidgets('bottom nav: four tabs around the centre action', (tester) async {
      _setSurface(tester, _small);
      var tapped = -1;
      var centre = false;
      await tester.pumpWidget(_app(Scaffold(
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
          onTap: (i) => tapped = i,
          onCenterAction: () => centre = true,
        ),
      )));
      await _expectClean(tester);

      for (final label in ['Home', 'Crews', 'Memories', 'You']) {
        expect(find.text(label), findsOneWidget);
      }

      await tester.tap(find.text('You'));
      await tester.pumpAndSettle();
      expect(tapped, 3);

      await tester.tap(find.bySemanticsLabel('Start a hangout'));
      await tester.pumpAndSettle();
      expect(centre, isTrue);
    });

    // Android requires 48dp touch targets; small pills draw 40dp inside one.
    testWidgets('small buttons keep a 48dp touch target', (tester) async {
      _setSurface(tester, _phone);
      await tester.pumpWidget(_app(Scaffold(
        body: Center(
          child: HangoutButton(
            label: 'Join',
            size: HangoutButtonSize.sm,
            onPressed: () {},
          ),
        ),
      )));
      await _expectClean(tester);
      expect(tester.getSize(find.byType(HangoutButton)).height,
          greaterThanOrEqualTo(48));
    });

    testWidgets('icon buttons keep a 48dp touch target', (tester) async {
      _setSurface(tester, _phone);
      await tester.pumpWidget(_app(Scaffold(
        body: Center(
          child: HangoutIconButton(
            icon: Icons.copy_rounded,
            size: 36,
            onPressed: () {},
          ),
        ),
      )));
      await _expectClean(tester);
      final size = tester.getSize(find.byType(HangoutIconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('section header with actions fits a narrow screen', (tester) async {
      _setSurface(tester, _small);
      await tester.pumpWidget(_app(Scaffold(
        body: SectionHeader(
          title: 'A long section title that has to give way',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HangoutButton(label: 'Join', size: HangoutButtonSize.sm, onPressed: () {}),
              HangoutButton(label: 'New', size: HangoutButtonSize.sm, onPressed: () {}),
            ],
          ),
        ),
      )));
      await _expectClean(tester);
    });

    testWidgets('list rows fit a narrow screen', (tester) async {
      _setSurface(tester, _small);
      await tester.pumpWidget(_app(Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: HangoutListGroup(
            children: [
              HangoutListRow(
                leading: const HangoutAvatar(name: 'Friday dinner lot', size: 40),
                title: 'A crew name long enough to need truncating',
                subtitle: '12 people · Food',
                trailing: HangoutButton(
                  label: 'Start',
                  size: HangoutButtonSize.sm,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      )));
      await _expectClean(tester);
    });

    testWidgets('stat chip pair fits a narrow screen', (tester) async {
      _setSurface(tester, _small);
      await tester.pumpWidget(_app(const Scaffold(
        body: Row(
          children: [
            Expanded(child: StatChip(label: 'Hangouts', value: '128')),
            SizedBox(width: 12),
            Expanded(child: StatChip(label: 'Crews', value: '14')),
          ],
        ),
      )));
      await _expectClean(tester);
    });
  });

  group('Screens', () {
    testWidgets('memories with a latest hangout and earlier ones', (tester) async {
      _setSurface(tester, _phone);
      await tester.pumpWidget(_app(Scaffold(
        body: MemoriesView(memories: [
          _memory('Example Biryani House', crew: 'Friday dinner lot', days: 1),
          _memory('Example Café', crew: 'Office crew', days: 4),
          _memory('Example Dhaba', days: 20, yes: 1, no: 0),
        ]),
      )));
      await _expectClean(tester);
      expect(find.text('Example Biryani House'), findsOneWidget);
      expect(find.text('4 of 5 said yes'), findsOneWidget);
      expect(find.text('Earlier'), findsOneWidget);
    });

    testWidgets('memories empty state', (tester) async {
      _setSurface(tester, _small);
      await tester.pumpWidget(_app(const Scaffold(body: MemoriesView(memories: []))));
      await _expectClean(tester);
      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('profile', (tester) async {
      _setSurface(tester, _phone);
      await tester.pumpWidget(_app(const Scaffold(
        body: ProfileView(
          nickname: 'CoolRex123',
          avatarId: 1,
          contact: 'someone@example.com',
          hangouts: 12,
          crews: 3,
        ),
      )));
      await _expectClean(tester);
      expect(find.text('@CoolRex123'), findsOneWidget);
    });

    testWidgets('profile survives a large text scale', (tester) async {
      _setSurface(tester, _small, textScale: 1.3);
      await tester.pumpWidget(_app(const Scaffold(
        body: ProfileView(
          nickname: 'SnazzyTricera999',
          avatarId: 4,
          contact: 'a.rather.long.address@example.com',
          hangouts: 128,
          crews: 14,
        ),
      )));
      await _expectClean(tester);
    });

    testWidgets('session filters', (tester) async {
      _setSurface(tester, _phone);
      await tester.pumpWidget(_app(
        const SessionFiltersScreen(mode: 'hunger', initial: SwipeFilters()),
      ));
      await _expectClean(tester);
    });

    // Regression: `Container(alignment:)` wraps its child in an Align, which
    // expands to the incoming max width — every choice pill once rendered as
    // a full-width bar.
    testWidgets('filter chips hug their labels', (tester) async {
      _setSurface(tester, _phone);
      await tester.pumpWidget(_app(
        const SessionFiltersScreen(mode: 'hunger', initial: SwipeFilters()),
      ));
      await tester.pumpAndSettle();

      final pizza = tester.getSize(find.ancestor(
        of: find.text('Pizza'),
        matching: find.byType(AnimatedContainer),
      ));
      expect(pizza.width, lessThan(160));
      expect(tester.getTopLeft(find.text('Burgers')).dy,
          tester.getTopLeft(find.text('Pizza')).dy);
    });
  });

  group('friendlyDate', () {
    final now = DateTime(2026, 9, 29, 20); // a Tuesday evening

    test('today and yesterday', () {
      expect(friendlyDate(DateTime(2026, 9, 29, 9), now: now), 'Today');
      expect(friendlyDate(DateTime(2026, 9, 28, 23), now: now), 'Yesterday');
    });

    test('weekday within the week, date beyond it', () {
      expect(friendlyDate(DateTime(2026, 9, 25), now: now), 'Fri');
      expect(friendlyDate(DateTime(2026, 9, 12), now: now), '12 Sep');
      expect(friendlyDate(DateTime(2025, 12, 31), now: now), '31 Dec 2025');
    });
  });
}
