import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/home_screen.dart';
import 'screens/swipe_screen.dart';
import 'screens/memory_screen.dart';
import 'screens/match_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/bottom_nav_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const DecisionlyApp());
}

class DecisionlyApp extends StatelessWidget {
  const DecisionlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Decisionly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _showMatch = false;

  void _goToSwipe() => setState(() => _currentIndex = 1);
  void _onMatch() => setState(() => _showMatch = true);
  void _dismissMatch() => setState(() { _showMatch = false; _currentIndex = 0; });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F8),
      extendBody: true, // For bottom nav bar if it is transparent
      body: Stack(children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _showMatch
            ? MatchScreen(key: const ValueKey('match'), onDismiss: _dismissMatch)
            : _buildPage(_currentIndex),
        ),
      ]),
      bottomNavigationBar: _showMatch ? null : BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0: return HomeScreen(key: const ValueKey('home'), onStartSwipe: _goToSwipe);
      case 1: return SwipeScreen(key: const ValueKey('swipe'), onMatch: _onMatch);
      case 2: return MemoryScreen(key: const ValueKey('memory'));
      case 3: return ProfileScreen(key: const ValueKey('profile'));
      default: return const SizedBox();
    }
  }
}
