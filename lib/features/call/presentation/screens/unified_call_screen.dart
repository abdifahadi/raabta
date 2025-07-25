import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../../domain/models/call_model.dart';
import '../../../../core/services/agora_unified_service.dart';
import '../../../../core/services/service_locator.dart';

/// Cross-platform call screen using Agora UIKit 1.3.10
/// Perfect support for Web, Android, iOS, Windows, macOS, and Linux
class UnifiedCallScreen extends StatefulWidget {
  final CallModel call;

  const UnifiedCallScreen({
    super.key,
    required this.call,
  });

  @override
  State<UnifiedCallScreen> createState() => _UnifiedCallScreenState();
}

class _UnifiedCallScreenState extends State<UnifiedCallScreen> with WidgetsBindingObserver {
  RtcEngine? _engine;
  late AgoraUnifiedService _agoraService;
  bool _isInitialized = false;
  String? _errorMessage;
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;
  late StreamSubscription _callEventSubscription;

  // Media controls state
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _agoraService = AgoraUnifiedService();
    _initializeCall();
    _listenToCallEvents();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app lifecycle for call management
    switch (state) {
      case AppLifecycleState.paused:
        if (kDebugMode) debugPrint('📱 App paused - call continues in background');
        break;
      case AppLifecycleState.resumed:
        if (kDebugMode) debugPrint('📱 App resumed - refreshing call state');
        break;
      case AppLifecycleState.detached:
        _endCall();
        break;
      default:
        break;
    }
  }

  void _listenToCallEvents() {
    _callEventSubscription = _agoraService.callEventStream.listen((event) {
      if (!mounted) return;
      
      final eventType = event['type'] as String;
      
      switch (eventType) {
        case 'userJoined':
          _showCallStatusMessage('User joined the call');
          break;
        case 'userLeft':
          _showCallStatusMessage('User left the call');
          break;
        case 'error':
          final errorCode = event['errorCode'] as String;
          _showCallStatusMessage('Call error: $errorCode', isError: true);
          break;
        case 'tokenWillExpire':
          _handleTokenExpiring();
          break;
      }
    });
  }

  void _showCallStatusMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleTokenExpiring() async {
    try {
      if (kDebugMode) debugPrint('🔑 Token expiring, refreshing...');
      // The service will handle token refresh automatically
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to refresh token: $e');
    }
  }

  Future<void> _initializeCall() async {
    try {
      if (kDebugMode) {
        debugPrint('🎥 Initializing Agora RTC Engine call...');
        debugPrint('📱 Platform: ${_getPlatformName()}');
        debugPrint('📞 Call Type: ${widget.call.callType.name}');
        debugPrint('🔗 Channel: ${widget.call.channelName}');
      }

      // Initialize the unified service
      await _agoraService.initialize();

      // Join the call
      await _agoraService.joinCall(
        channelName: widget.call.channelName,
        callType: widget.call.callType,
        uid: widget.call.callerId == widget.call.receiverId ? null : int.tryParse(widget.call.callerId),
      );

      // Get the engine
      _engine = _agoraService.engine;

      if (_engine != null) {
        setState(() {
          _isInitialized = true;
          _isVideoEnabled = widget.call.callType == CallType.video;
        });

        // Start call timer
        _startCallTimer();

        // Send call notification
        if (widget.call.callerId != widget.call.receiverId) {
          try {
            await ServiceLocator().notificationService.sendCallNotification(widget.call);
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ Failed to send call notification: $e');
          }
        }

        if (kDebugMode) debugPrint('✅ Agora UIKit call initialized successfully');
      } else {
        throw Exception('Failed to initialize Agora client');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to initialize call: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration = Duration(seconds: timer.tick);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
    } catch (e) {
      // Platform detection failed
    }
    return 'Unknown';
  }

  Future<void> _toggleMute() async {
    try {
      await _agoraService.toggleMute();
      setState(() {
        _isMuted = _agoraService.isMuted;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to toggle mute: $e');
    }
  }

  Future<void> _toggleVideo() async {
    try {
      await _agoraService.toggleVideo();
      setState(() {
        _isVideoEnabled = _agoraService.isVideoEnabled;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to toggle video: $e');
    }
  }

  Future<void> _toggleSpeaker() async {
    try {
      await _agoraService.toggleSpeaker();
      setState(() {
        _isSpeakerEnabled = _agoraService.isSpeakerEnabled;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to toggle speaker: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _agoraService.switchCamera();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to switch camera: $e');
    }
  }

  Future<void> _endCall() async {
    try {
      if (kDebugMode) debugPrint('🔚 Ending call...');
      
      _callTimer?.cancel();
      _callEventSubscription.cancel();
      
      await _agoraService.leaveCall();
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to end call: $e');
      // Force navigation back even if there's an error
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callTimer?.cancel();
    _callEventSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildCallInterface(),
      ),
    );
  }

  Widget _buildCallInterface() {
    if (_errorMessage != null) {
      return _buildErrorInterface();
    }

    if (!_isInitialized || _client == null) {
      return _buildLoadingInterface();
    }

    return Stack(
      children: [
        // Main call area
        _buildCallContent(),
        
        // Call controls overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildControlsOverlay(),
        ),
        
        // Call info overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildCallInfoOverlay(),
        ),
      ],
    );
  }

  Widget _buildCallContent() {
    if (widget.call.callType == CallType.audio) {
      return _buildAudioCallInterface();
    } else {
      return _buildVideoCallInterface();
    }
  }

  Widget _buildAudioCallInterface() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade600,
            Colors.blue.shade400,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // User avatar placeholder
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.person,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              widget.call.receiverId == widget.call.callerId ? 'Audio Call' : 'Incoming Audio Call',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Channel: ${widget.call.channelName}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCallInterface() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Remote video (full screen)
          if (_agoraService.remoteUsers.isNotEmpty)
            _agoraService.createRemoteVideoView(_agoraService.remoteUsers.first)
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Waiting for other participants...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          
          // Local video (floating)
          Positioned(
            top: 50,
            right: 20,
            width: 120,
            height: 160,
            child: _agoraService.createLocalVideoView(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.4),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            color: _isMuted ? Colors.red : Colors.white,
            backgroundColor: _isMuted ? Colors.red.withOpacity(0.2) : null,
            onPressed: _toggleMute,
            tooltip: _isMuted ? 'Unmute' : 'Mute',
          ),
          
          // Video toggle button (only for video calls)
          if (widget.call.callType == CallType.video)
            _buildControlButton(
              icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
              color: _isVideoEnabled ? Colors.white : Colors.red,
              backgroundColor: !_isVideoEnabled ? Colors.red.withOpacity(0.2) : null,
              onPressed: _toggleVideo,
              tooltip: _isVideoEnabled ? 'Turn off video' : 'Turn on video',
            ),
          
          // Speaker button (not on web)
          if (!kIsWeb)
            _buildControlButton(
              icon: _isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
              color: Colors.white,
              onPressed: _toggleSpeaker,
              tooltip: _isSpeakerEnabled ? 'Turn off speaker' : 'Turn on speaker',
            ),
          
          // Switch camera button (only for video calls and not on web)
          if (widget.call.callType == CallType.video && !kIsWeb)
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              color: Colors.white,
              onPressed: _switchCamera,
              tooltip: 'Switch camera',
            ),
          
          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            color: Colors.white,
            backgroundColor: Colors.red,
            onPressed: _endCall,
            tooltip: 'End call',
            isEndCall: true,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    required VoidCallback onPressed,
    String? tooltip,
    bool isEndCall = false,
  }) {
    Widget button = Container(
      width: isEndCall ? 64 : 56,
      height: isEndCall ? 64 : 56,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        border: backgroundColor == null 
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 1) 
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon, 
          color: backgroundColor != null ? Colors.white : color,
          size: isEndCall ? 32 : 24,
        ),
        onPressed: onPressed,
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }

  Widget _buildCallInfoOverlay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.4),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatDuration(_callDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.call.callType.name.toUpperCase()} CALL',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${_getPlatformName()} • Channel: ${widget.call.channelName}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingInterface() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade700,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Connecting to call...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we establish the connection',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorInterface() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.shade900,
            Colors.red.shade700,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Call Failed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}