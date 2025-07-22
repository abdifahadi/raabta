// lib/agora_web_stub_fix.dart
import 'package:raabta/utils/universal_platform_view_registry.dart';

/// Cross-platform safe registerViewFactory
void registerViewFactory(String viewType, dynamic factoryFunction) {
  UniversalPlatformViewRegistry.registerViewFactory(viewType, factoryFunction);
}
