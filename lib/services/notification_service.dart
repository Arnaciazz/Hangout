import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../screens/bill_screen.dart';
import '../screens/group_detail_screen.dart';
import '../screens/results_screen.dart';
import 'group_service.dart';
import 'session_service.dart';

/// Push notifications: this device's FCM token lives on the person's profile,
/// and the `notify` Edge Function (supabase/functions/notify) sends to it when
/// something happens in a crew. Every message carries `type`, and usually
/// `group_id` and `session_id`, so a tap can open the right screen.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final navigatorKey = GlobalKey<NavigatorState>();
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  final List<StreamSubscription<dynamic>> _subs = [];
  bool _started = false;

  /// False when Firebase couldn't start; everything here is then a no-op.
  bool enabled = true;

  SupabaseClient get _db => Supabase.instance.client;
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  /// Call once signed in. Asks for permission (Android 13+ shows the system
  /// prompt), saves the token, and starts listening. Safe to call again.
  Future<void> start() async {
    if (_started || !enabled) return;
    _started = true;
    try {
      final settings = await _fcm.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      await _saveToken(await _fcm.getToken());
      _subs
        ..add(_fcm.onTokenRefresh.listen(_saveToken))
        ..add(FirebaseMessaging.onMessage.listen(_showInApp))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen(_open));

      final initial = await _fcm.getInitialMessage();
      if (initial != null) _open(initial);
    } catch (e) {
      // No Play services, no network: the app works without push.
      debugPrint('[NotificationService] start: $e');
    }
  }

  /// Call before signing out, so this device stops getting the last
  /// person's notifications.
  Future<void> stop() async {
    if (!enabled) return;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _started = false;
    final uid = _db.auth.currentUser?.id;
    try {
      if (uid != null) {
        await _db.from('profiles').update({'fcm_token': null}).eq('id', uid);
      }
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('[NotificationService] stop: $e');
    }
  }

  Future<void> _saveToken(String? token) async {
    final uid = _db.auth.currentUser?.id;
    if (token == null || uid == null) return;
    try {
      await _db.from('profiles').update({'fcm_token': token}).eq('id', uid);
    } catch (e) {
      debugPrint('[NotificationService] saveToken: $e');
    }
  }

  /// In the foreground Android shows nothing on its own, so the message
  /// appears as a snackbar with a way into it.
  void _showInApp(RemoteMessage message) {
    final messenger = messengerKey.currentState;
    final context = messengerKey.currentContext;
    final n = message.notification;
    if (messenger == null || context == null || n == null) return;
    final text = [n.title, n.body].whereType<String>().join(' · ');
    messenger.showSnackBar(SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: context.l10n.notifyOpen,
        onPressed: () => _open(message),
      ),
    ));
  }

  Future<void> _open(RemoteMessage message) async {
    final data = message.data;
    final groupId = data['group_id'] as String?;
    final sessionId = data['session_id'] as String?;
    if (groupId == null) return;

    try {
      final group = await GroupService().getGroupDetails(groupId);
      final nav = navigatorKey.currentState;
      if (group == null || nav == null) return;

      final Widget screen;
      switch (data['type']) {
        case 'revealed' when sessionId != null:
          final session = await SessionService().getSessionWithPlaces(sessionId);
          screen = ResultsScreen(session: session, group: group, celebrate: true);
        case 'bill' when sessionId != null:
          screen = BillScreen(sessionId: sessionId, group: group);
        default:
          screen = GroupDetailScreen(group: group);
      }
      nav.push(MaterialPageRoute(builder: (_) => screen));
    } catch (e) {
      debugPrint('[NotificationService] open: $e');
    }
  }
}
