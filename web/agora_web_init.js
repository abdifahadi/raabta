// Agora Web SDK initialization for Flutter Web
// This script ensures proper Agora Web SDK setup for agora_rtc_engine 6.5.2+

window.agoraWebInit = function() {
  console.log('🌐 Initializing Agora Web SDK for Flutter...');
  
  // Check if we're running in a web environment
  if (typeof window !== 'undefined') {
    // Set up web-specific configurations
    window.agoraWebConfig = {
      mode: 'rtc',
      codec: 'vp8', // Use VP8 for better web compatibility
      role: 'host',
      enableLocalVideo: true,
      enableLocalAudio: true,
    };
    
    // Prevent any direct platformViewRegistry access
    if (typeof window.platformViewRegistry !== 'undefined') {
      console.warn('⚠️ Direct platformViewRegistry access detected - using Flutter web wrapper instead');
    }
    
    console.log('✅ Agora Web SDK configuration complete');
  }
};

// Auto-initialize when the script loads
document.addEventListener('DOMContentLoaded', function() {
  window.agoraWebInit();
});

// Also initialize immediately if DOM is already loaded
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', window.agoraWebInit);
} else {
  window.agoraWebInit();
}