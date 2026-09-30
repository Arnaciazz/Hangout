import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';

/// Opens [uri] in whatever app handles it (Maps, WhatsApp, a UPI app, the
/// browser). Tells the person when nothing could, instead of failing silently.
///
/// Launches directly rather than asking `canLaunchUrl` first: on Android 11+
/// that check is only as good as the manifest's `<queries>`, and a wrong
/// "no" there made buttons do nothing.
Future<bool> openLink(
  BuildContext context,
  Uri uri, {
  String? failMessage,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final message = failMessage ?? context.l10n.linkOpenFailed;

  bool opened;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
  return opened;
}

/// A WhatsApp share link. Opens the app when it's installed, the web
/// otherwise, so there's always somewhere for the message to go.
Uri whatsAppShareUri(String text) =>
    Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
