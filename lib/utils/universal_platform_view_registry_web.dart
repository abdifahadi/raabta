// ignore: undefined_prefixed_name
import 'dart:ui' as ui;

// Web-specific implementation using dart:ui for web platforms
void registerPlatformViewFactory(String viewType, dynamic factoryFunction) {
  try {
    // Use ui.platformViewRegistry for web platforms
    ui.platformViewRegistry.registerViewFactory(viewType, factoryFunction);
  } catch (e) {
    // Log error but don't crash the app
    if (identical(0, 0.0)) { // Debug mode check
      print('Web platform view registration failed for $viewType: $e');
    }
  }
}

bool isPlatformViewRegistryAvailable() {
  try {
    return ui.platformViewRegistry != null;
  } catch (e) {
    return false;
  }
}