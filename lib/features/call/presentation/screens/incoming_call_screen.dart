import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/call_model.dart';
import '../../../../core/services/service_locator.dart';

class IncomingCallScreen extends StatefulWidget {
  final CallModel call;

  const IncomingCallScreen({
    super.key,
    required this.call,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    
    // Set up animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
    _slideController.forward();
    
    // Start ringtone
    _startRingtone();
    
    // Set timeout for auto-decline
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        _timeoutCall();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _timeoutTimer?.cancel();
    _stopRingtone();
    super.dispose();
  }

  void _startRingtone() async {
    try {
      final ringtoneService = ServiceLocator().ringtoneServiceOrNull;
      if (ringtoneService != null) {
        await ringtoneService.startRingtone();
      }
    } catch (e) {
      // Ringtone failed, continue without it
      debugPrint('Failed to start ringtone: $e');
    }
  }

  void _stopRingtone() async {
    try {
      final ringtoneService = ServiceLocator().ringtoneServiceOrNull;
      if (ringtoneService != null) {
        await ringtoneService.stopRingtone();
      }
    } catch (e) {
      debugPrint('Failed to stop ringtone: $e');
    }
  }

  void _timeoutCall() async {
    // Force stop ringtone immediately
    try {
      final ringtoneService = ServiceLocator().ringtoneService;
      await ringtoneService.forceStopRingtone();
    } catch (e) {
      debugPrint('Error stopping ringtone on timeout: $e');
    }
    
    try {
      final callService = ServiceLocator().callService;
      // Use the proper timeout method to distinguish from user decline
      await callService.timeoutCall(widget.call);
      
      if (mounted) {
        Navigator.of(context).pop();
        // CallManager will handle showing the "Call Missed" feedback
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Container(
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
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Incoming ${widget.call.callType == CallType.video ? 'video' : 'audio'} call',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.call.callerName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Profile picture with pulse animation
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: widget.call.callerPhotoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: widget.call.callerPhotoUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.person,
                                          size: 80,
                                          color: Colors.white54,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.person,
                                          size: 80,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.person,
                                        size: 80,
                                        color: Colors.white54,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Call type indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.call.callType == CallType.video
                            ? Icons.videocam
                            : Icons.call,
                        color: Colors.white70,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.call.callType == CallType.video
                            ? 'Video Call'
                            : 'Voice Call',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Decline button
                      _buildActionButton(
                        onTap: _declineCall,
                        icon: Icons.call_end,
                        color: Colors.red,
                        size: 70,
                      ),
                      
                      // Answer button
                      _buildActionButton(
                        onTap: _answerCall,
                        icon: Icons.call,
                        color: Colors.green,
                        size: 70,
                      ),
                    ],
                  ),
                ),

                // Bottom padding
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.4,
        ),
      ),
    );
  }

  void _answerCall() async {
    _timeoutTimer?.cancel();
    
    // Force stop ringtone immediately
    try {
      final ringtoneService = ServiceLocator().ringtoneService;
      await ringtoneService.forceStopRingtone();
    } catch (e) {
      debugPrint('Error stopping ringtone: $e');
    }
    
    try {
      final callManager = ServiceLocator().callManager;
      await callManager.answerCall(widget.call);
      
      // Navigate to call screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/call',
          arguments: widget.call,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to answer call: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _declineCall() async {
    _timeoutTimer?.cancel();
    
    // Force stop ringtone immediately
    try {
      final ringtoneService = ServiceLocator().ringtoneService;
      await ringtoneService.forceStopRingtone();
    } catch (e) {
      debugPrint('Error stopping ringtone: $e');
    }
    
    try {
      final callManager = ServiceLocator().callManager;
      await callManager.declineCall(widget.call);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline call: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}