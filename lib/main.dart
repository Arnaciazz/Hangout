import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_config.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/hangout_background.dart';
import 'widgets/start_hangout_sheet.dart';
import 'widgets/hangout_logo.dart';
import 'screens/avatar_setup_screen.dart';
import 'screens/crews_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/memory_screen.dart';
import 'screens/profile_screen.dart';
import 'services/profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fonts ship in assets/google_fonts; never fall back to a network fetch.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in [
      ('Figtree', 'OFL-Figtree.txt'),
      ('Bricolage Grotesque', 'OFL-BricolageGrotesque.txt'),
    ]) {
      final text = await rootBundle.loadString('assets/google_fonts/$file');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });

  // Initialize Firebase (FCM + google-services.json)
  await Firebase.initializeApp();

  // Initialize Supabase (auth + database + realtime)
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,   // dark icons on light background
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const ShuffleApp());
}

class ShuffleApp extends StatelessWidget {
  const ShuffleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => HangoutBackground(child: child!),
      title: 'Hangout',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

// ─── Auth Gate ────────────────────────────────────────────────────────────────
// Listens to Supabase auth state. Shows LoginScreen when logged out,
// AppShell when logged in. No Navigator.push needed — reactive rebuild.

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // While waiting for the first auth event, show a blank loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _BootSplash();
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return const _SetupGate();
        }
        return const LoginScreen();
      },
    );
  }
}

// ─── Setup Gate ───────────────────────────────────────────────────────────────
// After login, checks whether the user has completed nickname/avatar setup.
// If not, shows AvatarSetupScreen first; otherwise goes straight to AppShell.

class _SetupGate extends StatefulWidget {
  const _SetupGate();

  @override
  State<_SetupGate> createState() => _SetupGateState();
}

class _SetupGateState extends State<_SetupGate> {
  late Future<bool> _setupFuture;

  @override
  void initState() {
    super.initState();
    _setupFuture = ProfileService().hasCompletedSetup();
  }

  void _refresh() {
    setState(() {
      _setupFuture = ProfileService().hasCompletedSetup();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _setupFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _BootSplash();
        }
        if (snapshot.data == true) {
          return const AppShell();
        }
        return AvatarSetupScreen(onSetupComplete: _refresh);
      },
    );
  }
}

// ─── App Shell ────────────────────────────────────────────────────────────────
// Four tabs around the design system's raised centre action. Tabs live in an
// IndexedStack so each keeps its scroll position; Memories and You reload when
// you return to them, so a hangout that just finished shows up.

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _refresh = 0;

  void _select(int i) {
    setState(() {
      if (i != _index) _refresh++;
      _index = i;
    });
  }

  void _startHangout() {
    HapticFeedback.mediumImpact();
    showStartHangoutSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            onOpenProfile: () => _select(3),
            onOpenMemories: () => _select(2),
          ),
          const CrewsScreen(),
          MemoryScreen(refreshToken: _refresh),
          ProfileScreen(refreshToken: _refresh),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _index,
        onTap: _select,
        onCenterAction: _startHangout,
      ),
    );
  }
}

// ─── Boot splash ──────────────────────────────────────────────────────────────
// Shown while auth and profile state resolve: the wordmark, still. No spinner
// until it's been long enough to need one.

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: HangoutWordmark(height: 36)),
    );
  }
}
