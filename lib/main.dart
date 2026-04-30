import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_config.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (FCM + google-services.json)
  await Firebase.initializeApp();

  // Initialize Supabase (auth + database + realtime)
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
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
      title: 'Shuffle',
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
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return const AppShell();
        }
        return const LoginScreen();
      },
    );
  }
}

// ─── App Shell ────────────────────────────────────────────────────────────────

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
