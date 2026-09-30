import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Listen to auth state changes and rebuild dependents
  AuthService() {
    _supabase.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  // ─── Google Sign-In ────────────────────────────────────────────────────────

  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: '1009098467654-4gh5qcduir67sv81rn1elakjrlhj7g7a.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return AuthResult.cancelled();

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return AuthResult.error('Google sign-in failed — no ID token.');

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      if (response.user == null) return AuthResult.error('Sign-in failed.');
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return AuthResult.error('Google sign-in failed: $e');
    }
  }

  // ─── Phone OTP — Step 1: send OTP ─────────────────────────────────────────

  Future<AuthResult> sendOtp(String phone) async {
    // Supabase expects E.164 format: +919876543210
    try {
      await _supabase.auth.signInWithOtp(phone: phone);
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Could not send OTP. Check your number and try again.');
    }
  }

  // ─── Phone OTP — Step 2: verify ──────────────────────────────────────────

  Future<AuthResult> verifyOtp(String phone, String otp) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );
      if (response.user == null) return AuthResult.error('Invalid OTP. Please try again.');
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Verification failed. Please try again.');
    }
  }

  // ─── Sign out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    // Unlink this device first, while still signed in to clear the token.
    await NotificationService.instance.stop();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Phone sign-ins have no Google session to end.
    }
    await _supabase.auth.signOut();
  }
}

// Simple result wrapper — avoids throwing across async boundaries in UI code
class AuthResult {
  final bool success;
  final bool cancelled;
  final String? errorMessage;

  AuthResult._({required this.success, required this.cancelled, this.errorMessage});

  factory AuthResult.success() => AuthResult._(success: true, cancelled: false);
  factory AuthResult.cancelled() => AuthResult._(success: false, cancelled: true);
  factory AuthResult.error(String msg) =>
      AuthResult._(success: false, cancelled: false, errorMessage: msg);
}
