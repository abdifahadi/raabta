import 'dart:ui_web' as ui_web;

/// Web implementation of platform view registry using dart:ui_web.
/// This file is only compiled on web platforms.
void registerViewFactoryImpl(String viewType, dynamic Function(int) factory) {
  // Use dart:ui_web which provides the correct platformViewRegistry for web
  ui_web.platformViewRegistry.registerViewFactory(viewType, factory);
}