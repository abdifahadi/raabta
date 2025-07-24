/// Stub implementation for non-web platforms.
/// This file is compiled on all platforms except web.
void registerViewFactoryImpl(String viewType, dynamic Function(int) factory) {
  // On non-web platforms, platformViewRegistry doesn't exist
  // So we safely do nothing here
  // This prevents compilation errors on mobile/desktop platforms
}