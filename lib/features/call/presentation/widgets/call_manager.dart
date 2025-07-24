import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/call_model.dart';
import '../../../../core/services/service_locator.dart';
import '../screens/incoming_call_screen.dart';
import '../screens/call_screen.dart';

class CallManager extends StatefulWidget {
  final Widget child;

  const CallManager({
    super.key,
    required this.child,
  });

  @override
  State<CallManager> createState() => _CallManagerState();
}

class _CallManagerState extends State<CallManager> {
  StreamSubscription? _incomingCallsSubscription;
  StreamSubscription? _currentCallSubscription;
  StreamSubscription? _callStatusSubscription;
  CallModel? _currentIncomingCall;
  
  // Navigation key for overlay navigation
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupCallListeners();
  }

  @override
  void dispose() {
    _incomingCallsSubscription?.cancel();
    _currentCallSubscription?.cancel();
    _callStatusSubscription?.cancel();
    super.dispose();
  }

  void _setupCallListeners() {
    try {
      final callRepository = ServiceLocator().callRepositoryOrNull;
      final callService = ServiceLocator().callServiceOrNull;
      final authService = ServiceLocator().authProviderOrNull;

      if (callRepository == null || authService?.currentUser == null) {
        // Services not ready yet, retry in a moment
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _setupCallListeners();
          }
        });
        return;
      }



      // Listen for incoming calls
      _incomingCallsSubscription = callRepository
          .listenToIncomingCalls()
          .listen((calls) {
        if (calls.isNotEmpty && mounted) {
          final call = calls.first;
          // Only show if it's a new incoming call and still ringing
          if (_currentIncomingCall?.callId != call.callId && 
              call.status == CallStatus.ringing) {
            _currentIncomingCall = call;
            _showIncomingCallScreen(call);
            _listenToCallStatus(call);
          }
        }
      });

      // Listen for current call changes
      if (callService != null) {
        _currentCallSubscription = callService.currentCallStream.listen((call) {
          if (mounted) {
            // If call ended, dismiss any call screens
            if (call == null) {
              _dismissCallScreens();
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting up call listeners: $e');
      }
    }
  }

  void _showIncomingCallScreen(CallModel call) {
    if (!mounted) return;

    // Use overlay to show incoming call screen
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return IncomingCallScreen(call: call);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    ).then((_) {
      // Reset incoming call when screen is dismissed
      _currentIncomingCall = null;
    });
  }

  void _listenToCallStatus(CallModel call) {
    _callStatusSubscription?.cancel();
    
    final callRepository = ServiceLocator().callRepositoryOrNull;
    if (callRepository == null) return;
    
    _callStatusSubscription = callRepository
        .getCallStream(call.callId)
        .listen((updatedCall) {
      if (updatedCall != null && mounted) {
        // Handle call status changes
        switch (updatedCall.status) {
          case CallStatus.accepted:
            // Call was accepted, dismiss incoming screen and navigate to call screen
            _dismissIncomingCallScreen();
            _navigateToCallScreen(updatedCall);
            break;
          case CallStatus.declined:
            // Call was declined, dismiss incoming screen and show feedback
            _dismissIncomingCallScreen();
            _showCallDeclinedFeedback();
            break;
          case CallStatus.ended:
          case CallStatus.cancelled:
            // Call ended or cancelled, dismiss screens
            _dismissIncomingCallScreen();
            break;
          case CallStatus.missed:
            // Call was missed (timeout), dismiss screens and show feedback
            _dismissIncomingCallScreen();
            _showCallMissedFeedback();
            break;
          case CallStatus.failed:
            // Call failed, dismiss screens and show error
            _dismissIncomingCallScreen();
            _showCallFailedFeedback();
            break;
          default:
            break;
        }
      }
    });
  }

  void _showCallDeclinedFeedback() {
    if (!mounted) return;
    
    // Show "Call Declined" message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.call_end, color: Colors.white),
            SizedBox(width: 8),
            Text('Call Declined'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showCallMissedFeedback() {
    if (!mounted) return;
    
    // Show "Call Missed" message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.phone_missed, color: Colors.white),
            SizedBox(width: 8),
            Text('Call Missed'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showCallFailedFeedback() {
    if (!mounted) return;
    
    // Show "Call Failed" message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Call Failed'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _dismissCallScreens() {
    // Dismiss any call-related screens when call ends
    _dismissIncomingCallScreen();
  }

  void _dismissIncomingCallScreen() {
    if (_currentIncomingCall != null) {
      _currentIncomingCall = null;
      _callStatusSubscription?.cancel();
      
      // Pop the incoming call screen if it's showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void _navigateToCallScreen(CallModel call) {
    if (!mounted) return;
    
    Navigator.of(context).pushNamed(
      '/call',
      arguments: call,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (settings) {
        // Handle call-related routes
        switch (settings.name) {
          case '/call':
            final call = settings.arguments as CallModel?;
            if (call != null) {
              return MaterialPageRoute(
                builder: (context) => CallScreen(call: call),
                settings: settings,
              );
            }
            break;
          case '/incoming-call':
            final call = settings.arguments as CallModel?;
            if (call != null) {
              return MaterialPageRoute(
                builder: (context) => IncomingCallScreen(call: call),
                settings: settings,
              );
            }
            break;
        }
        
        // Default route - return the child widget
        return MaterialPageRoute(
          builder: (context) => widget.child,
          settings: settings,
        );
      },
    );
  }
}

// Call notification widget for showing incoming call as overlay
class CallNotificationOverlay extends StatelessWidget {
  final CallModel call;
  final VoidCallback onAnswer;
  final VoidCallback onDecline;
  final VoidCallback onDismiss;

  const CallNotificationOverlay({
    super.key,
    required this.call,
    required this.onAnswer,
    required this.onDecline,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  call.callType == CallType.video ? Icons.videocam : Icons.call,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Incoming ${call.callType == CallType.video ? 'video' : 'audio'} call',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Caller info
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[800],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white54,
                    size: 25,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Name and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        call.callerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Incoming call...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline button
                _buildActionButton(
                  onTap: onDecline,
                  icon: Icons.call_end,
                  color: Colors.red,
                ),
                
                // Answer button
                _buildActionButton(
                  onTap: onAnswer,
                  icon: Icons.call,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}