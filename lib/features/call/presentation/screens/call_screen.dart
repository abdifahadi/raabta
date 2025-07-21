import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raabta/features/call/domain/models/call_model.dart';
import '../../../../core/services/call_service.dart';

class CallScreen extends StatefulWidget {
  final CallModel call;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.call,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  final bool _isVideoEnabled = true;
  bool _isConnecting = false;
  bool _localControlsVisible = true;
  Timer? _controlsTimer;

  // Mock remote UID for web compatibility
  int _remoteUid = 0;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _cleanupCall();
    super.dispose();
  }

  Future<void> _initializeCall() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      // Mock call initialization for web compatibility
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isConnecting = false;
        _remoteUid = 12345; // Mock remote user ID
      });
      
      _startControlsTimer();
    } catch (e) {
      _showErrorMessage('Failed to connect: $e');
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _localControlsVisible = false;
        });
      }
    });
  }

  void _toggleControlsVisibility() {
    setState(() {
      _localControlsVisible = !_localControlsVisible;
    });
    if (_localControlsVisible) {
      _startControlsTimer();
    }
  }

  Future<void> _cleanupCall() async {
    try {
      await _callService.endCall();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during cleanup: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: _toggleControlsVisibility,
          child: Stack(
            children: [
              // Main video area
              _buildMainVideoArea(),
              
              // Local video view (self view)
              if (widget.call.callType == CallType.video)
                _buildLocalVideoView(),
              
              // Call info overlay
              if (_localControlsVisible) _buildCallInfoOverlay(),
              
              // Call controls
              if (_localControlsVisible) _buildCallControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainVideoArea() {
    if (_isConnecting) {
      return _buildConnectingScreen();
    }

    if (widget.call.callType == CallType.video && _remoteUid != 0) {
      // For web compatibility, show placeholder instead of actual video
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: Text(
            'Video call active\n(Web preview mode)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    // Audio call or no remote video
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
          Container(
            width: 120,
            height: 120,
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
                          size: 50,
                          color: Colors.white54,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white54,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.call.receiverName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_isConnecting) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              color: Colors.white54,
            ),
          ],
          Text(
            _getCallStatusText(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalVideoView() {
    return Positioned(
      top: 50,
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
          child: _isVideoEnabled
              ? Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Text(
                      'Local video\n(Web preview)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              : Container(
                  color: Colors.grey[900],
                  child: const Icon(
                    Icons.videocam_off,
                    color: Colors.white54,
                    size: 30,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCallInfoOverlay() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: _localControlsVisible ? 0 : -100,
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
                    _getCallStatusText(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _remoteUid != 0 ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _remoteUid != 0 ? 'Connected' : 'Connecting...',
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

  Widget _buildCallControls() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: _localControlsVisible ? 0 : -100,
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
              icon: _callService.isMuted ? Icons.mic_off : Icons.mic,
              onPressed: () async {
                await _callService.toggleMute();
                setState(() {});
              },
            ),
            
            // Video toggle (only for video calls)
            if (widget.call.callType == CallType.video)
              _buildControlButton(
                icon: _callService.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                onPressed: () async {
                  await _callService.toggleVideo();
                  setState(() {});
                },
              ),
            
            // End call button
            _buildControlButton(
              icon: Icons.call_end,
              color: Colors.red,
              onPressed: _endCall,
            ),
            
            // Speaker button
            _buildControlButton(
              icon: _callService.isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
              onPressed: () async {
                await _callService.toggleSpeaker();
                setState(() {});
              },
            ),
            
            // Camera switch (only for video calls)
            if (widget.call.callType == CallType.video)
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                onPressed: () async {
                  // Camera switch functionality would go here
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    Color? color,
    required VoidCallback onPressed,
    bool isActive = true,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
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
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildConnectingScreen() {
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
          Container(
            width: 120,
            height: 120,
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
                          size: 50,
                          color: Colors.white54,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white54,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.call.receiverName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connecting...',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(
            color: Colors.white54,
          ),
        ],
      ),
    );
  }

  String _getCallStatusText() {
    if (_isConnecting) return 'Connecting...';
    if (_remoteUid != 0) return 'Connected';
    return widget.isIncoming ? 'Incoming call' : 'Calling...';
  }

  void _endCall() async {
    try {
      await _cleanupCall();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorMessage('Failed to end call: $e');
    }
  }

  void _showErrorMessage(String message) {
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