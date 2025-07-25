// ignore: undefined_prefixed_name
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'utils/universal_platform_view_registry.dart';
import 'core/platform/agora_platform_view_fix.dart';

/// Legacy compatibility wrapper for Agora web stub fixes
/// Provides drop-in replacements for problematic code patterns

/// Safe replacement for ui.platformViewRegistry.registerViewFactory
void safePlatformViewRegistryRegisterViewFactory(String viewType, dynamic factoryFunction) {
  try {
    if (kDebugMode) {
      debugPrint('🔧 Registering platform view factory: $viewType');
    }
    
    // Use the Agora-specific fix for better error handling
    AgoraPlatformViewFix.registerAgoraViewFactory(viewType, factoryFunction);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Platform view registration failed for $viewType: $e');
    }
    // Graceful fallback - don't crash the app
  }
}

/// Safe wrapper class for platform view registry operations
class SafeUiPlatformViewRegistry {
  /// Register a view factory with comprehensive error handling
  static void registerViewFactory(String viewType, dynamic factoryFunction) {
    safePlatformViewRegistryRegisterViewFactory(viewType, factoryFunction);
  }
  
  /// Check if platform view registry is available
  static bool get isAvailable {
    return UniversalPlatformViewRegistry.isAvailable;
  }
}

/// Extension on ui namespace to provide safe access
extension SafeUiExtension on dynamic {
  /// Safe platform view registry access
  SafeUiPlatformViewRegistry get platformViewRegistry => SafeUiPlatformViewRegistry();
}

/// Global instance for backward compatibility
final safeUi = SafeUiExtension(ui);

/// Initialize the Agora web stub fix
void initializeAgoraWebStubFix() {
  try {
    if (kDebugMode) {
      debugPrint('🚀 Initializing Agora web stub fix...');
    }
    
    // Initialize the platform view fix
    AgoraPlatformViewFix.initialize();
    
    if (kDebugMode) {
      debugPrint('✅ Agora web stub fix initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Agora web stub fix initialization failed: $e');
    }
    // Don't prevent app startup
  }
}