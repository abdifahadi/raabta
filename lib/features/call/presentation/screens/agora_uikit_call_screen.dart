import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:agora_uikit/agora_uikit.dart';

import '../../domain/models/call_model.dart';
import '../../../../core/services/agora_uikit_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/config/agora_config.dart';

/// Cross-platform call screen using Agora UIKit
/// Supports Web, Android, iOS, Windows, macOS, and Linux
class AgoraUIKitCallScreen extends StatefulWidget {
  final CallModel call;

  const AgoraUIKitCallScreen({
    super.key,
    required this.call,
  });

  @override
  State<AgoraUIKitCallScreen> createState() => _AgoraUIKitCallScreenState();
}

class _AgoraUIKitCallScreenState extends State<AgoraUIKitCallScreen> {
  AgoraClient? _client;
  late AgoraUIKitService _agoraService;
  bool _isInitialized = false;
  bool _isJoined = false;
  String? _errorMessage;
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _agoraService = ServiceLocator().agoraService as AgoraUIKitService;
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      if (kDebugMode) {
        debugPrint('🎥 Initializing Agora UIKit call...');
        debugPrint('📱 Platform: ${kIsWeb ? 'Web' : 'Native'}');
        debugPrint('📞 Call Type: ${widget.call.callType.name}');
        debugPrint('🔗 Channel: ${widget.call.channelName}');
      }

      // Initialize the service
      await _agoraService.initialize();

      // Join the call
      await _agoraService.joinCall(
        channelName: widget.call.channelName,
        callType: widget.call.callType,
        uid: int.tryParse(widget.call.callerId),
      );

      // Get the client for UI components
      _client = _agoraService.client;

      if (_client != null) {
        setState(() {
          _isInitialized = true;
          _isJoined = true;
        });

        _startCallTimer();

        if (kDebugMode) {
          debugPrint('✅ Call initialized successfully');
        }
      } else {
        throw Exception('Failed to create Agora client');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize call: $e');
      }
      setState(() {
        _errorMessage = 'Failed to initialize call: $e';
      });
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration = Duration(seconds: timer.tick);
      });
    });
  }

  Future<void> _endCall() async {
    try {
      _callTimer?.cancel();
      await _agoraService.leaveCall();
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error ending call: $e');
      }
    }
  }

  Future<void> _toggleMute() async {
    try {
      await _agoraService.toggleMute();
      setState(() {}); // Refresh UI
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error toggling mute: $e');
      }
    }
  }

  Future<void> _toggleVideo() async {
    try {
      await _agoraService.toggleVideo();
      setState(() {}); // Refresh UI
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error toggling video: $e');
      }
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _agoraService.switchCamera();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error switching camera: $e');
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (!_isInitialized || _client == null) {
      return _buildLoadingView();
    }

    return _buildCallView();
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 16),
          const Text(
            'Connecting...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Platform: ${kIsWeb ? 'Web' : 'Native'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallView() {
    return Stack(
      children: [
        // Main video area - uses AgoraVideoViewer for cross-platform support
        _buildVideoArea(),
        
        // Top bar with call info
        _buildTopBar(),
        
        // Bottom controls
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildVideoArea() {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: AgoraVideoViewer(
          client: _client!,
          layoutType: widget.call.callType == CallType.video ? Layout.floating : Layout.oneToOne,
          enableHostControls: false,
          showNumberOfUsers: false,
          showMicStatus: false,
          showAVState: false,
          floatingLayoutContainerHeight: MediaQuery.of(context).size.height * 0.3,
          floatingLayoutContainerWidth: MediaQuery.of(context).size.width * 0.3,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              widget.call.callType == CallType.video ? 'Video Call' : 'Voice Call',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDuration(_callDuration),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 4),
              const Text(
                'Web Platform',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute/Unmute button
            _buildControlButton(
              icon: _agoraService.isMuted ? Icons.mic_off : Icons.mic,
              onPressed: _toggleMute,
              backgroundColor: _agoraService.isMuted ? Colors.red : Colors.white.withOpacity(0.2),
              iconColor: _agoraService.isMuted ? Colors.white : Colors.white,
            ),
            
            // Video toggle button (only for video calls)
            if (widget.call.callType == CallType.video)
              _buildControlButton(
                icon: _agoraService.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                onPressed: _toggleVideo,
                backgroundColor: !_agoraService.isVideoEnabled ? Colors.red : Colors.white.withOpacity(0.2),
                iconColor: Colors.white,
              ),
            
            // Camera switch button (only for video calls on non-web platforms)
            if (widget.call.callType == CallType.video && !kIsWeb)
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                onPressed: _switchCamera,
                backgroundColor: Colors.white.withOpacity(0.2),
                iconColor: Colors.white,
              ),
            
            // End call button
            _buildControlButton(
              icon: Icons.call_end,
              onPressed: _endCall,
              backgroundColor: Colors.red,
              iconColor: Colors.white,
              size: 56,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
    double size = 48,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: iconColor,
          size: size * 0.5,
        ),
      ),
    );
  }
}