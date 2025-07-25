// Agora Web SDK initialization for Flutter Web
// This script ensures proper Agora Web SDK setup for agora_rtc_engine 6.5.2+
// Now works with the enhanced platformViewRegistry compatibility layer

console.log('🚀 Agora Web Init: Starting initialization for agora_rtc_engine 6.5.2+...');

// Check for dependencies
if (typeof AgoraRTC === 'undefined') {
  console.warn('⚠️ Agora Web Init: AgoraRTC not found, will be loaded by Flutter plugin');
} else {
  console.log('✅ Agora Web Init: AgoraRTC SDK detected');
}

window.agoraWebInit = function() {
  console.log('🔧 Agora Web Init: Configuring for Flutter agora_rtc_engine 6.5.2+...');
  
  // Ensure we're in a web environment
  if (typeof window === 'undefined') {
    console.error('❌ Agora Web Init: Not running in browser environment');
    return;
  }

  // Verify platformViewRegistry is available
  if (typeof window.ui !== 'undefined' && typeof window.ui.platformViewRegistry !== 'undefined') {
    console.log('✅ Agora Web Init: platformViewRegistry available via window.ui');
  } else if (typeof window.platformViewRegistry !== 'undefined') {
    console.log('✅ Agora Web Init: platformViewRegistry available at window level');
  } else {
    console.error('❌ Agora Web Init: platformViewRegistry not found!');
    return;
  }
  
  // Set up web-specific configurations for agora_rtc_engine
  window.agoraWebConfig = {
    mode: 'rtc',
    codec: 'vp8', // Use VP8 for better web compatibility
    role: 'host',
    enableLocalVideo: true,
    enableLocalAudio: true,
    // Enhanced configurations for agora_rtc_engine 6.5.2+
    audioProfile: {
      sampleRate: 48000,
      stereo: false,
      bitrate: 128, // Increased for better quality
      echoCancellation: true,
      noiseSuppression: true,
      autoGainControl: true
    },
    videoProfile: {
      width: 640,
      height: 480,
      frameRate: 30, // Increased for smoother video
      bitrate: 800   // Increased for better quality
    },
    // Web-specific optimizations
    webOptimizations: {
      enableWebCodecs: true,
      enableHardwareAcceleration: true,
      enableAudioWorklet: true,
      preferredVideoCodec: 'VP8',
      preferredAudioCodec: 'OPUS'
    }
  };
  
  // Set up Flutter Web video rendering compatibility
  window.agoraFlutterWebConfig = {
    enablePlatformView: true,
    enableTextureRenderer: true,
    preferHtmlRenderer: false, // Use CanvasKit for better performance
    platformViewCompatibility: 'enhanced', // Use our enhanced compatibility layer
  };
  
  // Enhanced platformViewRegistry wrapper for Agora compatibility
  if (typeof window.ui !== 'undefined' && typeof window.ui.platformViewRegistry !== 'undefined') {
    const originalRegisterViewFactory = window.ui.platformViewRegistry.registerViewFactory;
    
    window.ui.platformViewRegistry.registerViewFactory = function(viewTypeId, factory, options) {
      console.log('🔧 Agora Web Init: Enhanced registration for view factory:', viewTypeId);
      
      try {
        // Call original implementation
        const result = originalRegisterViewFactory.call(this, viewTypeId, factory, options);
        
        // Additional Agora-specific setup
        if (viewTypeId && viewTypeId.includes('agora')) {
          console.log('📹 Agora Web Init: Agora view factory registered:', viewTypeId);
          
          // Store Agora-specific metadata
          if (!window._agoraViewFactories) {
            window._agoraViewFactories = new Map();
          }
          window._agoraViewFactories.set(viewTypeId, {
            factory: factory,
            options: options || {},
            timestamp: Date.now()
          });
        }
        
        return result;
      } catch (e) {
        console.warn('⚠️ Agora Web Init: Fallback registration for:', viewTypeId, e);
        return true; // Fallback for compatibility
      }
    };
  }
  
  // Browser-specific optimizations
  const userAgent = navigator.userAgent.toLowerCase();
  if (userAgent.includes('chrome')) {
    console.log('🌐 Agora Web Init: Optimizing for Chrome');
    window.agoraWebConfig.browserOptimizations = {
      type: 'chrome',
      enableWebCodecs: true,
      enableInsertableStreams: true,
      enableWebAssembly: true
    };
  } else if (userAgent.includes('firefox')) {
    console.log('🌐 Agora Web Init: Optimizing for Firefox');
    window.agoraWebConfig.browserOptimizations = {
      type: 'firefox',
      enableWebCodecs: false, // Limited support
      enableInsertableStreams: false,
      enableWebAssembly: true
    };
  } else if (userAgent.includes('safari')) {
    console.log('🌐 Agora Web Init: Optimizing for Safari');
    window.agoraWebConfig.browserOptimizations = {
      type: 'safari',
      enableWebCodecs: false, // Not supported
      enableInsertableStreams: false,
      enableWebAssembly: true
    };
  } else {
    console.log('🌐 Agora Web Init: Using default browser optimizations');
    window.agoraWebConfig.browserOptimizations = {
      type: 'default',
      enableWebCodecs: false,
      enableInsertableStreams: false,
      enableWebAssembly: true
    };
  }
  
  console.log('✅ Agora Web Init: Configuration complete');
  console.log('📋 Agora Web Init: Final config:', window.agoraWebConfig);
};

// Initialize based on document state
function initializeWhenReady() {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      console.log('📄 Agora Web Init: DOM ready, initializing...');
      window.agoraWebInit();
    });
  } else {
    console.log('📄 Agora Web Init: Document already ready, initializing...');
    window.agoraWebInit();
  }
}

// Auto-initialize when the script loads
initializeWhenReady();

// Set up global flags and utilities
window.agoraWebInitialized = false;
window.addEventListener('load', function() {
  window.agoraWebInitialized = true;
  console.log('🎯 Agora Web Init: Complete and ready for Flutter');
});

// Export configuration getter for Flutter access
window.getAgoraWebConfig = function() {
  return window.agoraWebConfig || {};
};

// Enhanced debug helper
window.debugAgoraWeb = function() {
  console.log('🔍 Agora Web Debug Info:');
  console.log('  - Initialized:', window.agoraWebInitialized);
  console.log('  - Config:', window.agoraWebConfig);
  console.log('  - Flutter Config:', window.agoraFlutterWebConfig);
  console.log('  - PlatformViewRegistry (ui):', typeof window.ui?.platformViewRegistry);
  console.log('  - PlatformViewRegistry (window):', typeof window.platformViewRegistry);
  console.log('  - AgoraRTC:', typeof AgoraRTC);
  console.log('  - User Agent:', navigator.userAgent);
  console.log('  - View Factories:', window._platformViewFactories?.size || 0);
  console.log('  - Agora View Factories:', window._agoraViewFactories?.size || 0);
};

// Error handling for Agora-specific issues
window.addEventListener('error', function(event) {
  if (event.error && event.error.message && 
      event.error.message.includes('platformViewRegistry')) {
    console.error('❌ Agora Web Init: PlatformViewRegistry error detected:', event.error);
    console.log('🔧 Agora Web Init: Attempting recovery...');
    
    // Try to reinitialize
    setTimeout(function() {
      if (typeof window.agoraWebInit === 'function') {
        window.agoraWebInit();
      }
    }, 100);
  }
});

console.log('✅ Agora Web Init: Script loaded successfully');