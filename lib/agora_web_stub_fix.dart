// lib/agora_web_stub_fix.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui' as ui;

/// Cross-platform safe registerViewFactory
void registerViewFactory(String viewType, dynamic factoryFunction) {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewType, factoryFunction);
}
