import "package:flutter/foundation.dart";

// Conditional import: use stub for non-web, web implementation for web
import 'web_view_stub.dart' if (dart.library.html) 'web_view_web.dart';

@pragma('dart2js:tryInline')
void registerWebViewSafe() {
  // Only call registerWebView on web platforms to avoid runtime issues
  if (kIsWeb) {
    registerWebView();
  }
}