// lib/agora_web_stub_fix.dart
import 'package:raabta/utils/universal_platform_view_registry.dart';

/// Cross-platform safe registerViewFactory
/// Provides a safe way to register platform views across all platforms
void registerViewFactory(String viewType, dynamic factoryFunction) {
  UniversalPlatformViewRegistry.registerViewFactory(viewType, factoryFunction);
}

/// Safe registration method that doesn't throw exceptions
bool tryRegisterViewFactory(String viewType, dynamic factoryFunction) {
  return UniversalPlatformViewRegistry.tryRegisterViewFactory(viewType, factoryFunction);
}

/// Check if platform view registry is available
bool get isPlatformViewRegistryAvailable => UniversalPlatformViewRegistry.isAvailable;

/// Check if a view type is registered
bool isViewTypeRegistered(String viewType) {
  return UniversalPlatformViewRegistry.isViewTypeRegistered(viewType);
}
