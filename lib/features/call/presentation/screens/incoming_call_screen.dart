import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/call_model.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/ringtone_service.dart';
import 'unified_call_screen.dart';

/// Incoming call screen with accept/decline functionality
/// Includes ringtone service, call timeout, and proper UI
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  Timer? _callTimeoutTimer;
  Timer? _durationTimer;
  Duration _callDuration = Duration.zero;
  
  bool _isAnswering = false;
  bool _isDeclining = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _setupAnimations();
    _startRingtone();
    _startCallTimeout();
    _startDurationTimer();
    
    if (kDebugMode) {
      debugPrint('📞 Incoming call screen initialized');
      debugPrint('🔗 Call ID: ${widget.call.id}');
      debugPrint('👤 From: ${widget.call.callerId}');
      debugPrint('📱 Type: ${widget.call.callType.name}');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // Keep ringtone playing when app is minimized
        if (kDebugMode) debugPrint('📱 App paused - ringtone continues');
        break;
      case AppLifecycleState.resumed:
        // Ensure ringtone is still playing when app returns
        if (kDebugMode) debugPrint('📱 App resumed - checking ringtone state');
        _ensureRingtoneState();
        break;
      case AppLifecycleState.detached:
        _declineCall();
        break;
      default:
        break;
    }
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
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
    
    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  void _startRingtone() {
    try {
      RingtoneService().playWithTimeout(
        timeout: const Duration(seconds: 45), // Longer timeout for incoming calls
      );
      if (kDebugMode) debugPrint('🔔 Ringtone started for incoming call');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to start ringtone: $e');
    }
  }

  void _ensureRingtoneState() {
    if (!RingtoneService().isPlaying && !_isAnswering && !_isDeclining) {
      _startRingtone();
    }
  }

  void _startCallTimeout() {
    _callTimeoutTimer = Timer(const Duration(seconds: 45), () {
      if (mounted && !_isAnswering && !_isDeclining) {
        if (kDebugMode) debugPrint('⏰ Call timeout reached, auto-declining');
        _declineCall();
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  Future<void> _acceptCall() async {
    if (_isAnswering || _isDeclining) return;
    
    // Web platform does not support video calling
    if (kIsWeb) {
      _showWebNotSupportedDialog();
      return;
    }
    
    setState(() {
      _isAnswering = true;
    });

    try {
      if (kDebugMode) debugPrint('✅ Accepting incoming call');
      
      // Stop ringtone immediately
      await RingtoneService().forceStopRingtone();
      
      // Cancel timeout
      _callTimeoutTimer?.cancel();
      _durationTimer?.cancel();
      
      // Update call status
      try {
        await ServiceLocator().callRepository.updateCallStatus(
          widget.call.id, 
          CallStatus.active
        );
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Failed to update call status: $e');
      }
      
      // Navigate to call screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => UnifiedCallScreen(call: widget.call),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to accept call: $e');
      
      setState(() {
        _isAnswering = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineCall() async {
    if (_isAnswering || _isDeclining) return;
    
    setState(() {
      _isDeclining = true;
    });

    try {
      if (kDebugMode) debugPrint('❌ Declining incoming call');
      
      // Stop ringtone immediately
      await RingtoneService().forceStopRingtone();
      
      // Cancel timers
      _callTimeoutTimer?.cancel();
      _durationTimer?.cancel();
      
      // Update call status
      try {
        await ServiceLocator().callRepository.updateCallStatus(
          widget.call.id, 
          CallStatus.declined
        );
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Failed to update call status: $e');
      }
      
      // Navigate back
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to decline call: $e');
      
      // Force navigation back even on error
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Stop ringtone
    RingtoneService().forceStopRingtone();
    
    // Cancel timers
    _callTimeoutTimer?.cancel();
    _durationTimer?.cancel();
    
    // Dispose animations
    _pulseController.dispose();
    _slideController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900.withValues(alpha: 0.8),
              Colors.purple.shade900.withValues(alpha: 0.8),
              Colors.black.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildCallInfo()),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                const Text(
                  'INCOMING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            _formatDuration(_callDuration),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Caller avatar with pulse animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 160 * _pulseAnimation.value,
              height: 160 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                size: 80,
                color: Colors.white,
              ),
            );
          },
        ),
        
        const SizedBox(height: 30),
        
        // Caller name/ID
        const Text(
          'Incoming Call',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'From: ${widget.call.callerId}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Call type indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.call.callType == CallType.video 
                ? Colors.blue.withValues(alpha: 0.3)
                : Colors.green.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.call.callType == CallType.video 
                  ? Colors.blue
                  : Colors.green,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.call.callType == CallType.video 
                    ? Icons.videocam 
                    : Icons.phone,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.call.callType.name.toUpperCase()} CALL',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Channel info
        Text(
          'Channel: ${widget.call.channelName}',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Decline button
            GestureDetector(
              onTap: _isDeclining ? null : _declineCall,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isDeclining ? Colors.grey : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _isDeclining 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 40,
                    ),
              ),
            ),
            
            // Accept button
            GestureDetector(
              onTap: _isAnswering ? null : _acceptCall,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isAnswering ? Colors.grey : Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _isAnswering 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Icon(
                      widget.call.callType == CallType.video 
                          ? Icons.videocam 
                          : Icons.call,
                      color: Colors.white,
                      size: 40,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWebNotSupportedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Not Available'),
        content: const Text(
          'Video calling is not supported on the web platform. Please use the mobile app or desktop version for video calls.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _declineCall(); // Decline the call since we can't accept it
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}