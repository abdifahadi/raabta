import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/call_model.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/call_manager.dart';
import '../../../../core/services/ringtone_service.dart';
import 'package:flutter/foundation.dart';

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
  late Animation<Offset> _slideUpAnimation;

  Timer? _timeoutTimer;
  StreamSubscription? _callStatusSubscription;
  bool _isAnswering = false;
  bool _isDeclining = false;

  CallManager? _callManager;
  RingtoneService? _ringtoneService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _setupCallStatusListener();
    _startRingtoneWithTimeout();
    _setupCallTimeout();
  }

  /// Initialize services safely with fallback handling
  void _initializeServices() {
    try {
      if (ServiceLocator().isInitialized) {
        _callManager = ServiceLocator().callManagerOrNull;
        _ringtoneService = ServiceLocator().ringtoneServiceOrNull;
        if (kDebugMode) {
          debugPrint('✅ Incoming call screen services initialized successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ ServiceLocator not initialized - incoming call screen will run with limited functionality');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing incoming call screen services: $e');
      }
    }
  }

  void _initializeAnimations() {
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

    _slideUpAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));



    // Start animations
    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _timeoutTimer?.cancel();
    _callStatusSubscription?.cancel();
    _forceStopRingtone();
    super.dispose();
  }

  void _setupCallStatusListener() {
    try {
      if (_callManager != null) {
        _callStatusSubscription = _callManager!.currentCallStream.listen((call) {
          if (!mounted) return;
          
          if (call == null || call.callId != widget.call.callId) {
            // Call ended or changed, close this screen
            if (mounted && !_isAnswering && !_isDeclining) {
              Navigator.of(context).pop();
            }
            return;
          }
          
          // Handle call status changes
          if (call.status == CallStatus.cancelled || 
              call.status == CallStatus.ended ||
              call.status == CallStatus.missed) {
            if (mounted && !_isAnswering && !_isDeclining) {
              Navigator.of(context).pop();
            }
          }
        });
      } else {
        if (kDebugMode) debugPrint('⚠️ CallManager not available for status listener');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error setting up call status listener: $e');
    }
  }

  void _startRingtoneWithTimeout() async {
    try {
      if (_ringtoneService != null) {
        // Play ringtone with automatic timeout
        await _ringtoneService!.playWithTimeout(timeout: const Duration(seconds: 30));
      } else {
        if (kDebugMode) debugPrint('⚠️ RingtoneService not available');
      }
    } catch (e) {
      // Ringtone failed, continue without it
      if (kDebugMode) debugPrint('Failed to start ringtone: $e');
    }
  }

  Future<void> _forceStopRingtone() async {
    try {
      if (_ringtoneService != null) {
        await _ringtoneService!.forceStopRingtone();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to stop ringtone: $e');
    }
  }

  void _setupCallTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && !_isAnswering && !_isDeclining) {
        _timeoutCall();
      }
    });
  }

  void _timeoutCall() async {
    if (_isAnswering || _isDeclining) return;
    
    setState(() {
      _isDeclining = true;
    });
    
    // Force stop ringtone immediately
    await _forceStopRingtone();
    
    try {
      final callService = ServiceLocator().callServiceOrNull;
      if (callService != null) {
        // Use the proper timeout method to distinguish from user decline
        await callService.timeoutCall(widget.call);
      }
      
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
            position: _slideUpAnimation,
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
                        onTap: _isDeclining || _isAnswering ? null : _declineCall,
                        icon: Icons.call_end,
                        color: _isDeclining ? Colors.grey : Colors.red,
                        size: 70,
                        isLoading: _isDeclining,
                      ),
                      
                      // Answer button
                      _buildActionButton(
                        onTap: _isAnswering || _isDeclining ? null : _answerCall,
                        icon: Icons.call,
                        color: _isAnswering ? Colors.grey : Colors.green,
                        size: 70,
                        isLoading: _isAnswering,
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
    required VoidCallback? onTap,
    required IconData icon,
    required Color color,
    required double size,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: onTap != null ? [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ] : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: size * 0.3,
                  height: size * 0.3,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Icon(
                  icon,
                  color: Colors.white,
                  size: size * 0.4,
                ),
        ),
      ),
    );
  }

  void _answerCall() async {
    if (_isAnswering || _isDeclining) return;
    
    setState(() {
      _isAnswering = true;
    });
    
    _timeoutTimer?.cancel();
    
    // Force stop ringtone immediately when answer is pressed
    await _forceStopRingtone();
    
    try {
      if (_callManager != null) {
        await _callManager!.answerCall(widget.call);
        
        // Navigate to call screen immediately
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/call',
            arguments: widget.call.copyWith(status: CallStatus.accepted),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isAnswering = false;
      });
      
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
    if (_isDeclining || _isAnswering) return;
    
    setState(() {
      _isDeclining = true;
    });
    
    _timeoutTimer?.cancel();
    
    // Force stop ringtone immediately when decline is pressed
    await _forceStopRingtone();
    
    try {
      if (_callManager != null) {
        await _callManager!.declineCall(widget.call);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isDeclining = false;
      });
      
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