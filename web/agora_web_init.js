// Agora Web SDK initialization for Flutter Web
// This script ensures proper Agora Web SDK setup for agora_rtc_engine 6.5.2+

// Import the Agora Web SDK if not already loaded
if (typeof AgoraRTC === 'undefined') {
  console.log('🌐 Loading Agora Web SDK...');
  // The SDK will be loaded by the Flutter plugin automatically
}

window.agoraWebInit = function() {
  console.log('🚀 Initializing Agora Web SDK for Flutter agora_rtc_engine 6.5.2+...');
  
  // Check if we're running in a web environment
  if (typeof window !== 'undefined') {
    // Set up web-specific configurations for agora_rtc_engine
    window.agoraWebConfig = {
      mode: 'rtc',
      codec: 'vp8', // Use VP8 for better web compatibility
      role: 'host',
      enableLocalVideo: true,
      enableLocalAudio: true,
      // New configurations for agora_rtc_engine 6.5.2+
      audioProfile: {
        sampleRate: 48000,
        stereo: false,
        bitrate: 64
      },
      videoProfile: {
        width: 640,
        height: 480,
        frameRate: 15,
        bitrate: 400
      }
    };
    
    // Set up Flutter Web video rendering compatibility
    window.agoraFlutterWebConfig = {
      enablePlatformView: true,
      enableTextureRenderer: true,
      preferHtmlRenderer: false, // Use CanvasKit for better performance
    };
    
    // Override any direct platformViewRegistry access for compatibility
    if (typeof window.platformViewRegistry !== 'undefined') {
      const originalRegisterViewFactory = window.platformViewRegistry.registerViewFactory;
      window.platformViewRegistry.registerViewFactory = function(viewTypeId, factory) {
        console.log('🔧 Registering Agora view factory:', viewTypeId);
        try {
          return originalRegisterViewFactory.call(this, viewTypeId, factory);
        } catch (e) {
          console.warn('⚠️ Fallback platformViewRegistry registration for:', viewTypeId);
          return true; // Fallback for compatibility
        }
      };
    }
    
    // Set up performance optimizations for web
    if (typeof window.performance !== 'undefined') {
      window.agoraWebPerformance = {
        enableHardwareAcceleration: true,
        enableAudioWorklet: true,
        enableInsertableStreams: true,
      };
    }
    
    // Handle browser-specific optimizations
    const userAgent = navigator.userAgent;
    if (userAgent.includes('Chrome')) {
      console.log('🌐 Optimizing for Chrome browser');
      window.agoraWebConfig.browserOptimizations = {
        chrome: true,
        enableWebCodecs: true,
      };
    } else if (userAgent.includes('Firefox')) {
      console.log('🌐 Optimizing for Firefox browser');
      window.agoraWebConfig.browserOptimizations = {
        firefox: true,
        enableWebCodecs: false, // Not fully supported in Firefox yet
      };
    } else if (userAgent.includes('Safari')) {
      console.log('🌐 Optimizing for Safari browser');
      window.agoraWebConfig.browserOptimizations = {
        safari: true,
        enableWebCodecs: false, // Not supported in Safari
      };
    }
    
    console.log('✅ Agora Web SDK configuration complete for agora_rtc_engine 6.5.2+');
    console.log('📋 Configuration:', window.agoraWebConfig);
  }
};

// Handle DOM ready state
function initializeWhenReady() {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', window.agoraWebInit);
  } else {
    window.agoraWebInit();
  }
}

// Auto-initialize when the script loads
initializeWhenReady();

// Also set up a global flag for Flutter to check initialization status
window.agoraWebInitialized = false;
window.addEventListener('load', function() {
  window.agoraWebInitialized = true;
  console.log('🎯 Agora Web initialization complete and ready for Flutter');
});

// Export configuration for Flutter access
window.getAgoraWebConfig = function() {
  return window.agoraWebConfig || {};
};

// Debug helper function
window.debugAgoraWeb = function() {
  console.log('🔍 Agora Web Debug Info:');
  console.log('  - Initialized:', window.agoraWebInitialized);
  console.log('  - Config:', window.agoraWebConfig);
  console.log('  - Platform View Registry:', typeof window.platformViewRegistry);
  console.log('  - User Agent:', navigator.userAgent);
};