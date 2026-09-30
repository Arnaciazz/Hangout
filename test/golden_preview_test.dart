@Tags(['preview'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/l10n/l10n.dart';
import 'package:hangout/dev/fixtures.dart';
import 'package:hangout/screens/crews_screen.dart';
import 'package:hangout/screens/home_screen.dart';
import 'package:hangout/screens/memory_screen.dart';
import 'package:hangout/screens/bill_screen.dart';
import 'package:hangout/screens/place_detail_screen.dart';
import 'package:hangout/screens/place_swipe_screen.dart';
import 'package:hangout/screens/profile_screen.dart';
import 'package:hangout/screens/results_screen.dart';
import 'package:hangout/screens/session_filters_screen.dart';
import 'package:hangout/theme/app_theme.dart';
import 'package:hangout/widgets/bottom_nav_bar.dart';
import 'package:hangout/widgets/dino_avatar.dart';
import 'package:hangout/widgets/hangout_background.dart';

import 'support/preview_support.dart';

// Visual previews of the real screens, rendered through the engine to PNGs in
// test/preview/ so the design can be checked without a device:
//
//   flutter test --run-skipped --tags preview --update-goldens test/golden_preview_test.dart
//
// Fonts are the bundled brand faces, icons are real Material Icons, shadows are
// real. Every photo is a SYNTHETIC stand-in (test/fixtures/synthetic_place.png)
// and all data comes from lib/dev/fixtures.dart — nothing here is real.

const _phone = Size(390, 844);
final _today = DateTime(2026, 9, 25, 19, 30); // a Friday evening

void _noop() {}

Widget _host(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, c) => HangoutBackground(child: c!),
      home: child,
    );

/// A tab as `AppShell` composes it: the screen body over the shared nav bar.
Widget _tab(Widget body, int index) => Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: body,
      bottomNavigationBar: BottomNavBar(
        currentIndex: index,
        onTap: (_) {},
        onCenterAction: () {},
      ),
    );

void _surface(WidgetTester tester, Size size) {
  // flutter_test flattens shadows by default; render them as the app does.
  debugDisableShadows = false;
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<void> _shoot(WidgetTester tester, String name) async {
  await settleImages(tester);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('preview/$name.png'),
  );
  // The test binding checks this is back to its default before tear-down.
  debugDisableShadows = true;
}

void main() {
  setUpAll(setUpPreviewRendering);

  testWidgets('preview: home', (tester) async {
    _surface(tester, _phone);
    await tester.pumpWidget(_host(_tab(
      HomeView(
        now: _today,
        nickname: 'CoolRex123',
        avatarId: 1,
        active: fixtureActive,
        lastTime: fixtureMemories(_today).first,
        // Live handlers, so controls render enabled as they do in the app.
        onEat: _noop,
        onExplore: _noop,
        onOpenActive: _noop,
        onOpenProfile: _noop,
        onOpenMemories: _noop,
      ),
      0,
    )));
    await _shoot(tester, 'home');
  });

  testWidgets('preview: crews', (tester) async {
    _surface(tester, _phone);
    await tester.pumpWidget(_host(_tab(
      CrewsView(
        crews: fixtureCrews(),
        onCreate: _noop,
        onJoin: _noop,
        onOpen: (_) {},
      ),
      1,
    )));
    await _shoot(tester, 'crews');
  });

  testWidgets('preview: memories', (tester) async {
    _surface(tester, _phone);
    await tester.pumpWidget(_host(_tab(
      MemoriesView(
        memories: fixtureMemories(_today),
        onOpen: (_) {},
        onDidntGo: (_) {},
      ),
      2,
    )));
    await _shoot(tester, 'memories');
  });

  testWidgets('preview: profile', (tester) async {
    _surface(tester, _phone);
    await tester.pumpWidget(_host(_tab(
      const ProfileView(
        nickname: 'CoolRex123',
        avatarId: 1,
        contact: 'someone@example.com',
        hangouts: 12,
        crews: 3,
        onEdit: _noop,
        onLogOut: _noop,
      ),
      3,
    )));
    await _shoot(tester, 'profile');
  });

  testWidgets('preview: filters', (tester) async {
    _surface(tester, _phone);
    await tester.pumpWidget(_host(
      const SessionFiltersScreen(mode: 'hunger', initial: SwipeFilters()),
    ));
    await _shoot(tester, 'filters');
  });

  testWidgets('preview: swipe', (tester) async {
    _surface(tester, _phone);
    await tester.pumpWidget(
        _host(PlaceSwipeScreen(session: fixtureSwipeSession())));
    await _shoot(tester, 'swipe');
  });

  Widget page(Widget body) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(leading: const BackButton()),
        body: body,
      );

  testWidgets('preview: results', (tester) async {
    _surface(tester, _phone);
    await tester.pumpWidget(_host(page(ResultsView(
      results: fixtureResults(),
      mode: 'hunger',
      group: fixtureCrews().first,
      myId: 'u2',
      onOpenPlace: (_) {},
      onOpenBill: _noop,
      onStartAgain: _noop,
    ))));
    await _shoot(tester, 'results');
  });

  testWidgets('preview: solo results', (tester) async {
    _surface(tester, _phone);
    await tester.pumpWidget(_host(page(ResultsView(
      results: fixtureResults(),
      mode: 'hunger',
      group: null,
      onOpenPlace: (_) {},
      onStartAgain: _noop,
    ))));
    await _shoot(tester, 'results_solo');
  });

  testWidgets('preview: bill, owing', (tester) async {
    _surface(tester, _phone);
    await tester.pumpWidget(_host(page(BillView(
      bill: fixtureBill(),
      myId: 'u2',
      placeName: 'Example Biryani House',
      onAction: (_, [__]) {},
    ))));
    await _shoot(tester, 'bill_owe');
  });

  testWidgets('preview: bill, paid it', (tester) async {
    _surface(tester, _phone);
    await tester.pumpWidget(_host(page(BillView(
      bill: fixtureBill(secondPaid: false),
      myId: 'u0',
      placeName: 'Example Biryani House',
      onAction: (_, [__]) {},
    ))));
    await _shoot(tester, 'bill_payer');
  });

  testWidgets('preview: place detail', (tester) async {
    _surface(tester, _phone);
    await tester.pumpWidget(_host(PlaceDetailScreen(
      place: fixtureSwipeSession().places.first,
      mode: 'hunger',
      voteLine: '4 of 5 said yes',
    )));
    await _shoot(tester, 'place_detail');
  });

  testWidgets('preview: avatars', (tester) async {
    _surface(tester, const Size(390, 300));
    await tester.pumpWidget(_host(Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < kDinoAvatars.length; i++)
              DinoAvatar(avatarId: i, size: 56, selected: i == 2),
          ],
        ),
      ),
    )));
    await _shoot(tester, 'avatars');
  });
}
