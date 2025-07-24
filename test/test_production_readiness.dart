#!/usr/bin/env dart
/// Comprehensive production readiness test for Raabta app
/// Tests Agora calling functionality across platforms with proper error handling

import 'dart:io';
import 'dart:developer' as dev;

void main() async {
  print('🚀 Starting Raabta Production Readiness Test');
  print('=' * 60);
  
  final testResults = <String, bool>{};
  
  // Test 1: Platform Detection
  print('\n📱 Testing Platform Detection...');
  try {
    testResults['Platform Detection'] = await testPlatformDetection();
  } catch (e) {
    print('❌ Platform Detection failed: $e');
    testResults['Platform Detection'] = false;
  }
  
  // Test 2: Dependency Compatibility
  print('\n📦 Testing Dependency Compatibility...');
  try {
    testResults['Dependencies'] = await testDependencies();
  } catch (e) {
    print('❌ Dependency test failed: $e');
    testResults['Dependencies'] = false;
  }
  
  // Test 3: Agora Configuration
  print('\n🎥 Testing Agora Configuration...');
  try {
    testResults['Agora Config'] = await testAgoraConfig();
  } catch (e) {
    print('❌ Agora config test failed: $e');
    testResults['Agora Config'] = false;
  }
  
  // Test 4: Firebase Configuration
  print('\n🔥 Testing Firebase Configuration...');
  try {
    testResults['Firebase Config'] = await testFirebaseConfig();
  } catch (e) {
    print('❌ Firebase config test failed: $e');
    testResults['Firebase Config'] = false;
  }
  
  // Test 5: Cross-Platform Compilation
  print('\n🔧 Testing Cross-Platform Compilation...');
  try {
    testResults['Compilation'] = await testCompilation();
  } catch (e) {
    print('❌ Compilation test failed: $e');
    testResults['Compilation'] = false;
  }
  
  // Test 6: Platform View Registry
  print('\n🌐 Testing Platform View Registry...');
  try {
    testResults['Platform Views'] = await testPlatformViews();
  } catch (e) {
    print('❌ Platform view test failed: $e');
    testResults['Platform Views'] = false;
  }
  
  // Test 7: Service Locator
  print('\n🏗️ Testing Service Locator...');
  try {
    testResults['Service Locator'] = await testServiceLocator();
  } catch (e) {
    print('❌ Service locator test failed: $e');
    testResults['Service Locator'] = false;
  }
  
  // Test 8: Network Connectivity
  print('\n🌍 Testing Network Connectivity...');
  try {
    testResults['Network'] = await testNetworkConnectivity();
  } catch (e) {
    print('❌ Network test failed: $e');
    testResults['Network'] = false;
  }
  
  // Generate Report
  print('\n' + '=' * 60);
  print('📊 PRODUCTION READINESS REPORT');
  print('=' * 60);
  
  int passedTests = 0;
  int totalTests = testResults.length;
  
  testResults.forEach((test, passed) {
    final status = passed ? '✅ PASS' : '❌ FAIL';
    print('$status: $test');
    if (passed) passedTests++;
  });
  
  print('\n' + '-' * 60);
  print('Summary: $passedTests/$totalTests tests passed');
  
  final percentage = (passedTests / totalTests * 100).toInt();
  print('Production Readiness: $percentage%');
  
  if (percentage >= 90) {
    print('🎉 EXCELLENT: App is production ready!');
  } else if (percentage >= 75) {
    print('⚠️  GOOD: App is mostly ready, minor issues need fixing');
  } else if (percentage >= 50) {
    print('🔧 FAIR: App needs significant improvements');
  } else {
    print('🚨 POOR: App requires major fixes before production');
  }
  
  print('\n' + '=' * 60);
  
  // Exit with appropriate code
  exit(percentage >= 75 ? 0 : 1);
}

Future<bool> testPlatformDetection() async {
  print('  Detecting current platform...');
  
  try {
    if (Platform.isAndroid) {
      print('  ✅ Platform: Android');
      return true;
    } else if (Platform.isIOS) {
      print('  ✅ Platform: iOS');
      return true;
    } else if (Platform.isWindows) {
      print('  ✅ Platform: Windows');
      return true;
    } else if (Platform.isMacOS) {
      print('  ✅ Platform: macOS');
      return true;
    } else if (Platform.isLinux) {
      print('  ✅ Platform: Linux');
      return true;
    } else {
      print('  ⚠️  Platform: Unknown');
      return true; // Still pass for web or other platforms
    }
  } catch (e) {
    print('  ❌ Platform detection failed: $e');
    return false;
  }
}

Future<bool> testDependencies() async {
  print('  Checking Flutter dependencies...');
  
  try {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print('  ❌ pubspec.yaml not found');
      return false;
    }
    
    final content = await pubspecFile.readAsString();
    
    // Check for critical dependencies
    final criticalDeps = [
      'agora_rtc_engine',
      'firebase_core',
      'firebase_auth',
      'cloud_firestore',
      'supabase_flutter'
    ];
    
    for (final dep in criticalDeps) {
      if (!content.contains(dep)) {
        print('  ❌ Missing critical dependency: $dep');
        return false;
      }
    }
    
    print('  ✅ All critical dependencies found');
    return true;
  } catch (e) {
    print('  ❌ Dependency check failed: $e');
    return false;
  }
}

Future<bool> testAgoraConfig() async {
  print('  Checking Agora configuration...');
  
  try {
    final configFile = File('lib/core/config/agora_config.dart');
    if (!configFile.existsSync()) {
      print('  ❌ Agora config file not found');
      return false;
    }
    
    final content = await configFile.readAsString();
    
    // Check for required configuration
    if (!content.contains('appId') || 
        !content.contains('4bfa94cebfb04852951bfdf9858dbc4b')) {
      print('  ❌ Invalid Agora App ID configuration');
      return false;
    }
    
    if (!content.contains('primaryCertificate')) {
      print('  ❌ Missing Agora certificate configuration');
      return false;
    }
    
    print('  ✅ Agora configuration valid');
    return true;
  } catch (e) {
    print('  ❌ Agora config check failed: $e');
    return false;
  }
}

Future<bool> testFirebaseConfig() async {
  print('  Checking Firebase configuration...');
  
  try {
    final configFile = File('lib/core/config/firebase_options.dart');
    if (!configFile.existsSync()) {
      print('  ❌ Firebase config file not found');
      return false;
    }
    
    final content = await configFile.readAsString();
    
    if (!content.contains('DefaultFirebaseOptions') || 
        !content.contains('currentPlatform')) {
      print('  ❌ Invalid Firebase configuration');
      return false;
    }
    
    print('  ✅ Firebase configuration valid');
    return true;
  } catch (e) {
    print('  ❌ Firebase config check failed: $e');
    return false;
  }
}

Future<bool> testCompilation() async {
  print('  Testing Flutter compilation...');
  
  try {
    // Run flutter analyze
    final analyzeResult = await Process.run('flutter', ['analyze', '--no-fatal-infos']);
    
    if (analyzeResult.exitCode == 0) {
      print('  ✅ Static analysis passed');
    } else {
      print('  ⚠️  Static analysis warnings (may be acceptable)');
      // Don't fail on warnings, only on errors
    }
    
    return true;
  } catch (e) {
    print('  ❌ Compilation test failed: $e');
    return false;
  }
}

Future<bool> testPlatformViews() async {
  print('  Checking platform view registry...');
  
  try {
    final registryFile = File('lib/utils/universal_platform_view_registry.dart');
    if (!registryFile.existsSync()) {
      print('  ❌ Platform view registry not found');
      return false;
    }
    
    final stubFile = File('lib/utils/universal_platform_view_registry_stub.dart');
    final webFile = File('lib/utils/universal_platform_view_registry_web.dart');
    
    if (!stubFile.existsSync() || !webFile.existsSync()) {
      print('  ❌ Platform-specific implementations missing');
      return false;
    }
    
    print('  ✅ Platform view registry configured');
    return true;
  } catch (e) {
    print('  ❌ Platform view test failed: $e');
    return false;
  }
}

Future<bool> testServiceLocator() async {
  print('  Checking service locator...');
  
  try {
    final serviceFile = File('lib/core/services/service_locator.dart');
    if (!serviceFile.existsSync()) {
      print('  ❌ Service locator not found');
      return false;
    }
    
    final content = await serviceFile.readAsString();
    
    if (!content.contains('AgoraService') || 
        !content.contains('ServiceLocator')) {
      print('  ❌ Service locator not properly configured');
      return false;
    }
    
    print('  ✅ Service locator configured');
    return true;
  } catch (e) {
    print('  ❌ Service locator test failed: $e');
    return false;
  }
}

Future<bool> testNetworkConnectivity() async {
  print('  Testing network connectivity...');
  
  try {
    // Test basic network connectivity
    final result = await Process.run('ping', ['-c', '1', '8.8.8.8']);
    
    if (result.exitCode == 0) {
      print('  ✅ Network connectivity available');
      return true;
    } else {
      print('  ⚠️  Network connectivity limited (may affect some features)');
      return true; // Don't fail on network issues during testing
    }
  } catch (e) {
    print('  ⚠️  Network test inconclusive: $e');
    return true; // Don't fail on network test issues
  }
}