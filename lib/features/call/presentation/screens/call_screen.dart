import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/call_model.dart';
import '../../../../core/services/service_locator.dart';

class CallScreen extends StatefulWidget {
  final CallModel call;

  const CallScreen({
    super.key,
    required this.call,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final callService = ServiceLocator().callService;
  
  // UI state
  bool _isControlsVisible = true;
  Timer? _controlsTimer;
  int _remoteUid = 0;
  bool _remoteVideoMuted = false;
  bool _remoteAudioMuted = false; // Add missing variable
  
  // Call duration
  Timer? _durationTimer;
  int _duration = 0;
  
  // Streams
  StreamSubscription? _callEventSubscription;
  StreamSubscription? _callStateSubscription;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _startDurationTimer();
    _startControlsTimer();
    
    // Keep screen on during call
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _durationTimer?.cancel();
    _callEventSubscription?.cancel();
    _callStateSubscription?.cancel();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    super.dispose();
  }

  void _setupListeners() {
    // Listen to call events
    _callEventSubscription = callService.callEventStream.listen((event) {
      if (!mounted) return;
      
      switch (event['type']) {
        case 'userJoined':
          setState(() {
            _remoteUid = event['remoteUid'];
          });
          break;
          
        case 'userOffline':
          setState(() {
            _remoteUid = 0;
          });
          // End call if remote user leaves
          _endCall();
          break;
          
        case 'remoteVideoStateChanged':
          setState(() {
            _remoteVideoMuted = event['state'] != 'remoteVideoStateDecoding';
          });
          break;
          
        case 'remoteAudioStateChanged':
          setState(() {
            _remoteAudioMuted = event['state'] != 'remoteAudioStateDecoding';
          });
          break;
          
        case 'error':
          _showError('Call error: ${event['message']}');
          break;
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration++;
        });
      }
    });
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isVideoCall = widget.call.callType == CallType.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isControlsVisible = !_isControlsVisible;
          });
          if (_isControlsVisible) {
            _startControlsTimer();
          }
        },
        child: Stack(
          children: [
            // Remote video or avatar
            if (isVideoCall && _remoteUid != 0 && !_remoteVideoMuted)
              _buildRemoteVideo()
            else
              _buildRemoteAvatar(),
            
            // Local video (for video calls)
            if (isVideoCall) _buildLocalVideo(),
            
            // Top bar with call info
            _buildTopBar(),
            
            // Bottom controls
            if (_isControlsVisible) _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteVideo() {
    return SizedBox.expand(
      child: _remoteUid != 0
          ? AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: callService.engine!,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.call.channelName),
              ),
            )
          : Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  Widget _buildRemoteAvatar() {
    final isConnected = _remoteUid != 0;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2C1810),
            Color(0xFF1A1A1A),
            Color(0xFF0D0D0D),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Profile picture
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: widget.call.receiverPhotoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.call.receiverPhotoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white54,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white54,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Name
          Text(
            widget.call.receiverName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Status
          Text(
            isConnected ? 'Connected' : 'Connecting...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          
          if (!isConnected) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              color: Colors.white54,
              strokeWidth: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalVideo() {
    return Positioned(
      top: 100,
      right: 16,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: callService.isVideoEnabled
              ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: callService.engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                )
              : Container(
                  color: Colors.grey[900],
                  child: const Icon(
                    Icons.videocam_off,
                    color: Colors.white54,
                    size: 32,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: _isControlsVisible ? 0 : -100,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back button (minimize call)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 28,
              ),
            ),
            
            Expanded(
              child: Column(
                children: [
                  Text(
                    widget.call.receiverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Connection indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _remoteUid != 0 ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _remoteUid != 0 ? 'Connected' : 'Connecting',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: _isControlsVisible ? 0 : -150,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            _buildControlButton(
              icon: callService.isMuted ? Icons.mic_off : Icons.mic,
              isActive: !callService.isMuted,
              onPressed: () {
                callService.toggleMute();
                setState(() {});
              },
            ),
            
            // Video button (for video calls)
            if (widget.call.callType == CallType.video)
              _buildControlButton(
                icon: callService.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                isActive: callService.isVideoEnabled,
                onPressed: () {
                  callService.toggleVideo();
                  setState(() {});
                },
              ),
            
            // End call button
            _buildControlButton(
              icon: Icons.call_end,
              color: Colors.red,
              size: 65,
              onPressed: _endCall,
            ),
            
            // Speaker button
            _buildControlButton(
              icon: callService.isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
              isActive: callService.isSpeakerEnabled,
              onPressed: () {
                callService.toggleSpeaker();
                setState(() {});
              },
            ),
            
            // Camera switch (for video calls)
            if (widget.call.callType == CallType.video)
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                onPressed: () => callService.switchCamera(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    Color? color,
    bool isActive = true,
    double size = 55,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color ?? (isActive ? Colors.white.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.8)),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.4,
        ),
      ),
    );
  }

  void _endCall() async {
    try {
      await callService.endCall();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Failed to end call: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}