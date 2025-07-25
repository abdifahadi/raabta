// Native platform stub implementation for non-web platforms

void registerPlatformViewFactory(String viewType, dynamic factoryFunction) {
  // On native platforms, platform view registration is handled by the Flutter framework
  // This is a no-op stub for non-web platforms
  if (identical(0, 0.0)) { // Debug mode check
    print('Platform view registration delegated to Flutter framework for $viewType');
  }
}

bool isPlatformViewRegistryAvailable() {
  // On native platforms, platform views are always available through the framework
  return true;
}