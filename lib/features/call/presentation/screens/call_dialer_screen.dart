import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/call_model.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../features/auth/domain/models/user_profile_model.dart';

class CallDialerScreen extends StatefulWidget {
  final UserProfileModel targetUser;

  const CallDialerScreen({
    super.key,
    required this.targetUser,
  });

  @override
  State<CallDialerScreen> createState() => _CallDialerScreenState();
}

class _CallDialerScreenState extends State<CallDialerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isInitiatingCall = false;
  StreamSubscription? _callStatusSubscription;

  @override
  void initState() {
    super.initState();
    
    // Set up pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _callStatusSubscription?.cancel();
    super.dispose();
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Start Call',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Profile section
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Profile picture with pulse animation
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: widget.targetUser.photoUrl?.isNotEmpty == true
                                  ? CachedNetworkImage(
                                      imageUrl: widget.targetUser.photoUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.person,
                                          size: 70,
                                          color: Colors.white54,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.person,
                                          size: 70,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.person,
                                        size: 70,
                                        color: Colors.white54,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Name
                    Text(
                      widget.targetUser.displayName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Email or phone
                    if (widget.targetUser.email.isNotEmpty)
                      Text(
                        widget.targetUser.email,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),

                    const SizedBox(height: 60),

                    // Call type selection
                    Text(
                      'Choose call type',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Call buttons
              if (_isInitiatingCall)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Initiating call...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Audio call button
                      _buildCallButton(
                        onTap: () => _initiateCall(CallType.audio),
                        icon: Icons.call,
                        label: 'Audio Call',
                        color: Colors.green,
                        size: 80,
                      ),
                      
                      // Video call button
                      _buildCallButton(
                        onTap: () => _initiateCall(CallType.video),
                        icon: Icons.videocam,
                        label: 'Video Call',
                        color: Colors.blue,
                        size: 80,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    required double size,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
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
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _initiateCall(CallType callType) async {
    if (_isInitiatingCall) return;

    // Web platform does not support video calling
    if (kIsWeb) {
      _showWebNotSupportedDialog();
      return;
    }

    setState(() {
      _isInitiatingCall = true;
    });

    try {
      // Check if ServiceLocator is initialized
      if (!ServiceLocator().isInitialized) {
        throw Exception('Call services not initialized. Please restart the app.');
      }
      
      final callManager = ServiceLocator().callManagerOrNull;
      final callRepository = ServiceLocator().callRepositoryOrNull;
      final authService = ServiceLocator().authProviderOrNull;
      final userProfileRepository = ServiceLocator().userProfileRepositoryOrNull;
      
      if (callManager == null || callRepository == null || authService == null || userProfileRepository == null) {
        throw Exception('Required call services are not available.');
      }

      // Check if we can start a new call
      if (!callManager.canStartNewCall) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Already in a call or call in progress'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isInitiatingCall = false;
        });
        return;
      }

      // Get current user profile
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw StateError('User not authenticated');
      }

      final currentUserProfile = await userProfileRepository.getUserProfile(currentUser.uid);
      if (currentUserProfile == null) {
        throw StateError('Current user profile not found');
      }

      // Start the call using CallManager
      final call = await callManager.startCall(
        receiverId: widget.targetUser.uid,
        callType: callType,
        callerName: currentUserProfile.displayName,
        callerPhotoUrl: currentUserProfile.photoUrl ?? '',
        receiverName: widget.targetUser.displayName,
        receiverPhotoUrl: widget.targetUser.photoUrl ?? '',
      );

      // Listen to call status changes instead of immediately navigating
      final statusSubscription = callRepository.getCallStream(call.callId).listen((updatedCall) {
        if (updatedCall != null && mounted) {
          switch (updatedCall.status) {
            case CallStatus.accepted:
              // Call accepted, navigate to call screen
              Navigator.of(context).pushReplacementNamed(
                '/call',
                arguments: updatedCall,
              );
              break;
            case CallStatus.declined:
              // Call declined, show message and go back
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Call declined'),
                  backgroundColor: Colors.red,
                ),
              );
              break;
            case CallStatus.missed:
              // Call missed (timeout), show message and go back
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No answer'),
                  backgroundColor: Colors.orange,
                ),
              );
              break;
            case CallStatus.failed:
              // Call failed, show error and go back
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Call failed'),
                  backgroundColor: Colors.red,
                ),
              );
              break;
            default:
              break;
          }
        }
      });

      // Store subscription for cleanup
      _callStatusSubscription?.cancel();
      _callStatusSubscription = statusSubscription;

      // Show calling UI instead of immediately navigating
      _showCallingDialog(call);

    } catch (e) {
      setState(() {
        _isInitiatingCall = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCallingDialog(CallModel call) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Calling ${widget.targetUser.displayName}...',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              call.callType == CallType.video ? 'Video Call' : 'Audio Call',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Store context before async operation
              final navigator = Navigator.of(context);
              
              // Cancel the call
              try {
                final callService = ServiceLocator().callServiceOrNull;
                if (callService != null) {
                  await callService.cancelCall(call);
                }
                if (mounted) {
                  navigator.pop(); // Close dialog
                  navigator.pop(); // Go back to previous screen
                }
              } catch (e) {
                if (mounted) {
                  navigator.pop(); // Close dialog anyway
                  navigator.pop(); // Go back to previous screen
                }
              }
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((_) {
      // Reset state when dialog is dismissed
      setState(() {
        _isInitiatingCall = false;
      });
      _callStatusSubscription?.cancel();
    });
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
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}