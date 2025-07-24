import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../../domain/models/call_model.dart';
import '../../../../core/services/agora_uikit_service.dart';
import '../../../../core/services/service_locator.dart';

/// Cross-platform call screen using Agora RTC Engine
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
  RtcEngine? _engine;
  late AgoraUIKitService _agoraService;
  bool _isInitialized = false;
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
        debugPrint('🎥 Initializing Agora RTC Engine call...');
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
        uid: widget.call.callerId == widget.call.receiverId ? null : int.tryParse(widget.call.callerId),
      );

      // Get the engine from the service
      _engine = _agoraService.engine;

      if (_engine != null) {
        setState(() {
          _isInitialized = true;
        });

        // Start call timer
        _startCallTimer();

        if (kDebugMode) debugPrint('✅ Agora RTC Engine call initialized successfully');
      } else {
        throw Exception('Failed to initialize Agora engine');
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

  Future<void> _endCall() async {
    try {
      if (kDebugMode) debugPrint('🔚 Ending call...');
      
      _callTimer?.cancel();
      
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
    _callTimer?.cancel();
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

    if (!_isInitialized || _engine == null) {
      return _buildLoadingInterface();
    }

    return Stack(
      children: [
        // Main video area
        _buildVideoArea(),
        
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

  Widget _buildVideoArea() {
    if (widget.call.callType == CallType.audio) {
      // For audio calls, show a placeholder with user avatar
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey,
                child: Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Audio Call',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // For video calls, show video view
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Remote video (main view)
          if (_agoraService.remoteUsers.isNotEmpty)
            _agoraService.createRemoteVideoView(_agoraService.remoteUsers.first)
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Waiting for remote user...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          
          // Local video (picture-in-picture)
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _agoraService.createLocalVideoView(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Mute button
          _buildControlButton(
            icon: _agoraService.isMuted ? Icons.mic_off : Icons.mic,
            color: _agoraService.isMuted ? Colors.red : Colors.white,
            onPressed: () async {
              await _agoraService.toggleMute();
              setState(() {});
            },
          ),
          
          // Video toggle button (only for video calls)
          if (widget.call.callType == CallType.video)
            _buildControlButton(
              icon: _agoraService.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
              color: _agoraService.isVideoEnabled ? Colors.white : Colors.red,
              onPressed: () async {
                await _agoraService.toggleVideo();
                setState(() {});
              },
            ),
          
          // Speaker button (not applicable on web)
          if (!kIsWeb)
            _buildControlButton(
              icon: _agoraService.isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
              color: Colors.white,
              onPressed: () async {
                await _agoraService.toggleSpeaker();
                setState(() {});
              },
            ),
          
          // Switch camera button (only for video calls and not on web)
          if (widget.call.callType == CallType.video && !kIsWeb)
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              color: Colors.white,
              onPressed: () async {
                await _agoraService.switchCamera();
              },
            ),
          
          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            color: Colors.red,
            backgroundColor: Colors.red,
            onPressed: _endCall,
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
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        border: backgroundColor == null 
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 1) 
            : null,
      ),
      child: IconButton(
        icon: Icon(icon, color: backgroundColor != null ? Colors.white : color),
        onPressed: onPressed,
      ),
    );
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
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatDuration(_callDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Call Type: ${widget.call.callType.name.toUpperCase()}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            'Channel: ${widget.call.channelName}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingInterface() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Connecting to call...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorInterface() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}