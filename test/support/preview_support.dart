import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Makes widget-test renders look like the app:
/// - brand fonts come from assets/google_fonts (bundled, no network);
/// - Material Icons load from the Flutter SDK, so icons draw instead of boxes;
/// - every network image is served [photoPath], a synthetic stand-in photo.
///
/// Call once from `setUpAll`.
Future<void> setUpPreviewRendering({
  String photoPath = 'test/fixtures/synthetic_place.png',
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;

  final icons = File('${_flutterRoot()}/bin/cache/artifacts/material_fonts/'
      'materialicons-regular.otf');
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
  await loader.load();

  HttpOverrides.global =
      _PhotoHttpOverrides(File(photoPath).readAsBytesSync());
}

/// Decodes every `Image` currently in the tree (real async is needed for image
/// codecs), then settles. Call after `pumpWidget`, before capturing.
Future<void> settleImages(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}

/// The SDK root, found by walking up from the running test binary.
String _flutterRoot() {
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 12; i++) {
    if (Directory('${dir.path}/bin/cache/artifacts/material_fonts')
        .existsSync()) {
      return dir.path;
    }
    dir = dir.parent;
  }
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null) return env;
  throw StateError('Could not locate the Flutter SDK for Material Icons.');
}

// ─── A minimal HttpClient that answers every GET with one image ───────────────

class _PhotoHttpOverrides extends HttpOverrides {
  final Uint8List bytes;

  _PhotoHttpOverrides(this.bytes);

  @override
  HttpClient createHttpClient(SecurityContext? context) => _PhotoClient(bytes);
}

class _PhotoClient extends Fake implements HttpClient {
  final Uint8List bytes;

  _PhotoClient(this.bytes);

  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _PhotoRequest(bytes);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _PhotoRequest(bytes);
}

class _PhotoRequest extends Fake implements HttpClientRequest {
  final Uint8List bytes;

  _PhotoRequest(this.bytes);

  @override
  final HttpHeaders headers = _NoHeaders();

  @override
  Future<HttpClientResponse> close() async => _PhotoResponse(bytes);
}

class _NoHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _PhotoResponse extends Fake implements HttpClientResponse {
  final Uint8List bytes;

  _PhotoResponse(this.bytes);

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<List<int>>.value(bytes).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
}
