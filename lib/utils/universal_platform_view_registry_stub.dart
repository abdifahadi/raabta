// lib/utils/universal_platform_view_registry_stub.dart

/// Stub implementation for non-web platforms
void registerViewFactory(String viewType, dynamic factoryFunction) {
  // No-op for non-web platforms
  // Platform views are handled natively on mobile platforms
}

/// Platform view registry availability - false for non-web platforms
bool get isAvailable => false;
