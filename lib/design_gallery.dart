import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dev/fixtures.dart';
import 'l10n/app_localizations.dart';
import 'screens/crews_screen.dart';
import 'screens/home_screen.dart';
import 'screens/memory_screen.dart';
import 'screens/place_swipe_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/session_filters_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/hangout_background.dart';
import 'widgets/start_hangout_sheet.dart';

/// Dev-only entry point: the real screens with illustrative fixture data, no
/// Firebase or Supabase needed.
///
///   flutter run -t lib/design_gallery.dart -d chrome
///
/// Everything you can reach works as in the app: the four tabs, the "+" sheet,
/// Eat / Explore → filters → the deck, "Swipe" → the deck, a memory → results.
/// The deck is always the same fixture places, whatever the filters. Anything
/// that needs the live backend (crew details, creating or joining a crew,
/// editing your profile) shows a note instead. Places have no photos here —
/// those come from the Places API — so photo areas show their placeholder.
///
/// Nothing in the app imports this file.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const _GalleryApp());
}

class _GalleryApp extends StatelessWidget {
  const _GalleryApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hangout — gallery',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) => HangoutBackground(child: child!),
      home: const _GalleryShell(),
    );
  }
}

class _GalleryShell extends StatefulWidget {
  const _GalleryShell();

  @override
  State<_GalleryShell> createState() => _GalleryShellState();
}

class _GalleryShellState extends State<_GalleryShell> {
  int _index = 0;

  void _needsBackend() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Needs the live backend — not available in the gallery.'),
      ));
  }

  // The app creates a session from the filters; here they go straight to the
  // fixture deck, which ignores them.
  Future<void> _filters(String mode) async {
    final filters = await Navigator.of(context).push<SwipeFilters>(
      MaterialPageRoute(
        builder: (_) => SessionFiltersScreen(
          mode: mode,
          initial: const SwipeFilters(),
        ),
      ),
    );
    if (!mounted || filters == null) return;
    _swipe();
  }

  void _swipe() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlaceSwipeScreen(
        session: fixtureSwipeSession(withPhoto: false),
      ),
    ));
  }

  void _results() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultsScreen(
        session: fixtureRevealedSession,
        group: fixtureCrews().first,
        precomputedResults: fixtureResults(withPhoto: false),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final memories = fixtureMemories(now, withPhoto: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomeView(
            now: now,
            nickname: 'CoolRex123',
            avatarId: 1,
            active: fixtureActive,
            lastTime: memories.first,
            onEat: () => _filters('hunger'),
            onExplore: () => _filters('travel'),
            onOpenActive: _swipe,
            onOpenProfile: () => setState(() => _index = 3),
            onOpenMemories: () => setState(() => _index = 2),
          ),
          CrewsView(
            crews: fixtureCrews(),
            onCreate: _needsBackend,
            onJoin: _needsBackend,
            onOpen: (_) => _needsBackend(),
          ),
          MemoriesView(memories: memories, onOpen: (_) => _results()),
          ProfileView(
            nickname: 'CoolRex123',
            avatarId: 1,
            contact: 'someone@example.com',
            hangouts: memories.length,
            crews: fixtureCrews().length,
            onEdit: _needsBackend,
            onLogOut: _needsBackend,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        onCenterAction: () => showStartHangoutSheet(context, onPick: _filters),
      ),
    );
  }
}
