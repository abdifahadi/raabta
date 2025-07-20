class AgoraConfig {
  // Agora App ID provided by the user
  static const String appId = '4bfa94cebfb04852951bfdf9858dbc4b';
  
  // Primary Certificate (for token generation in Phase 2)
  static const String primaryCertificate = '8919043495b3435fba0ab1aa2973f29b';
  
  // Default channel name prefix
  static const String channelPrefix = 'raabta_call_';
  
  // Token expiration time (24 hours in seconds)
  static const int tokenExpirationTime = 24 * 3600;
  
  // Default call timeout (30 seconds)
  static const int callTimeout = 30;
  
  // Audio settings
  static const int audioProfile = 1; // Default audio profile
  static const int audioScenario = 1; // Default audio scenario
  
  // Video settings
  static const int videoWidth = 640;
  static const int videoHeight = 480;
  static const int videoFrameRate = 15;
  static const int videoBitrate = 400;
  
  // Generate channel name from user IDs
  static String generateChannelName(String callerId, String receiverId) {
    // Sort IDs to ensure consistent channel names regardless of who initiates
    final sortedIds = [callerId, receiverId]..sort();
    return '${channelPrefix}${sortedIds[0]}_${sortedIds[1]}';
  }
  
  // Generate unique call ID
  static String generateCallId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}