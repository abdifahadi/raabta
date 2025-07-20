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
                                color: Colors.white.withOpacity(0.3),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
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

    setState(() {
      _isInitiatingCall = true;
    });

    try {
      final callService = ServiceLocator().callService;
      final authService = ServiceLocator().authProvider;
      final userProfileRepository = ServiceLocator().userProfileRepository;

      // Get current user profile
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw StateError('User not authenticated');
      }

      final currentUserProfile = await userProfileRepository.getUserProfile(currentUser.uid);
      if (currentUserProfile == null) {
        throw StateError('Current user profile not found');
      }

      // Start the call
      final call = await callService.startCall(
        receiverId: widget.targetUser.uid,
        callType: callType,
        callerName: currentUserProfile.displayName,
        callerPhotoUrl: currentUserProfile.photoUrl ?? '',
        receiverName: widget.targetUser.displayName,
        receiverPhotoUrl: widget.targetUser.photoUrl ?? '',
      );

      // Navigate to call screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/call',
          arguments: call,
        );
      }
    } catch (e) {
      setState(() {
        _isInitiatingCall = false;
      });

      if (mounted) {
        String errorMessage = 'Failed to start call';
        
        if (e.toString().contains('permissions')) {
          errorMessage = 'Please grant microphone and camera permissions to make calls';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection';
        } else if (e.toString().contains('already in a call')) {
          errorMessage = 'You are already in a call';
        }

        _showErrorDialog(errorMessage);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          'Call Failed',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}