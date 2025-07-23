import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/call/domain/models/call_model.dart';
import 'call_service.dart';
import 'service_locator.dart';

/// Centralized call manager for handling call state and preventing conflicts
class CallManager {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  // Current call state
  CallModel? _currentCall;
  bool _isInCall = false;
  bool _isJoiningCall = false;
  Timer? _callStateCleanupTimer;

  // Stream controllers for state management
  final StreamController<CallModel?> _currentCallController = 
      StreamController<CallModel?>.broadcast();
  final StreamController<bool> _callStateController = 
      StreamController<bool>.broadcast();

  // Getters
  CallModel? get currentCall => _currentCall;
  bool get isInCall => _isInCall;
  bool get isJoiningCall => _isJoiningCall;
  bool get canStartNewCall => !_isInCall && !_isJoiningCall && _currentCall == null;

  // Streams
  Stream<CallModel?> get currentCallStream => _currentCallController.stream;
  Stream<bool> get callStateStream => _callStateController.stream;

  /// Start a new call with conflict prevention
  Future<CallModel> startCall({
    required String receiverId,
    required CallType callType,
    required String callerName,
    required String callerPhotoUrl,
    required String receiverName,
    required String receiverPhotoUrl,
  }) async {
    try {
      // Check if we can start a new call
      if (!canStartNewCall) {
        if (_isInCall) {
          throw Exception('Already in an active call. Please end the current call first.');
        }
        if (_isJoiningCall) {
          throw Exception('Currently joining a call. Please wait.');
        }
        if (_currentCall != null) {
          throw Exception('Call already in progress. Please wait for it to complete.');
        }
      }

      if (kDebugMode) {
        debugPrint('🎯 CallManager: Starting new call to $receiverId');
      }

      _isJoiningCall = true;
      _callStateController.add(_isJoiningCall);

      // Cancel any existing cleanup timer
      _callStateCleanupTimer?.cancel();

      final callService = ServiceLocator().callService;
      
      // Start the call
      final call = await callService.startCall(
        receiverId: receiverId,
        callType: callType,
        callerName: callerName,
        callerPhotoUrl: callerPhotoUrl,
        receiverName: receiverName,
        receiverPhotoUrl: receiverPhotoUrl,
      );

      // Update state
      _currentCall = call;
      _currentCallController.add(_currentCall);

      if (kDebugMode) {
        debugPrint('✅ CallManager: Call started successfully: ${call.callId}');
      }

      return call;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CallManager: Failed to start call: $e');
      }
      // Clean up state on error
      await _cleanupCallState();
      rethrow;
    } finally {
      _isJoiningCall = false;
      _callStateController.add(_isJoiningCall);
    }
  }

  /// Answer an incoming call
  Future<void> answerCall(CallModel call) async {
    try {
      if (_isInCall) {
        throw Exception('Already in an active call');
      }

      if (kDebugMode) {
        debugPrint('📞 CallManager: Answering call ${call.callId}');
      }

      _isJoiningCall = true;
      _callStateController.add(_isJoiningCall);

      // Cancel any existing cleanup timer
      _callStateCleanupTimer?.cancel();

      final callService = ServiceLocator().callService;
      await callService.answerCall(call);

      // Update state
      _currentCall = call.copyWith(status: CallStatus.connected);
      _isInCall = true;
      _currentCallController.add(_currentCall);
      _callStateController.add(_isInCall);

      if (kDebugMode) {
        debugPrint('✅ CallManager: Call answered successfully: ${call.callId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CallManager: Failed to answer call: $e');
      }
      // Clean up state on error
      await _cleanupCallState();
      rethrow;
    } finally {
      _isJoiningCall = false;
      _callStateController.add(_isJoiningCall);
    }
  }

  /// Decline an incoming call
  Future<void> declineCall(CallModel call) async {
    try {
      if (kDebugMode) {
        debugPrint('❌ CallManager: Declining call ${call.callId}');
      }

      final callService = ServiceLocator().callService;
      await callService.declineCall(call);

      // Clean up state
      await _cleanupCallState();

      if (kDebugMode) {
        debugPrint('✅ CallManager: Call declined successfully: ${call.callId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CallManager: Failed to decline call: $e');
      }
      // Clean up state even on error
      await _cleanupCallState();
      rethrow;
    }
  }

  /// End the current call
  Future<void> endCall() async {
    try {
      if (_currentCall == null && !_isInCall) {
        if (kDebugMode) {
          debugPrint('⚠️ CallManager: No active call to end');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('🔚 CallManager: Ending call ${_currentCall?.callId}');
      }

      final callService = ServiceLocator().callService;
      await callService.endCall();

      if (kDebugMode) {
        debugPrint('✅ CallManager: Call ended successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CallManager: Failed to end call properly: $e');
      }
      // Continue with cleanup even if ending fails
    } finally {
      // Always clean up state
      await _cleanupCallState();
    }
  }

  /// Cancel an outgoing call
  Future<void> cancelCall(CallModel call) async {
    try {
      if (kDebugMode) {
        debugPrint('🚫 CallManager: Cancelling call ${call.callId}');
      }

      final callService = ServiceLocator().callService;
      await callService.cancelCall(call);

      if (kDebugMode) {
        debugPrint('✅ CallManager: Call cancelled successfully: ${call.callId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CallManager: Failed to cancel call: $e');
      }
      rethrow;
    } finally {
      // Always clean up state
      await _cleanupCallState();
    }
  }

  /// Update call status
  void updateCallStatus(CallModel updatedCall) {
    if (_currentCall?.callId == updatedCall.callId) {
      _currentCall = updatedCall;
      _currentCallController.add(_currentCall);

      // Update in-call state based on status
      final wasInCall = _isInCall;
      _isInCall = updatedCall.status == CallStatus.connected || 
                  updatedCall.status == CallStatus.accepted;

      if (wasInCall != _isInCall) {
        _callStateController.add(_isInCall);
      }

      // Clean up state if call has ended
      if (updatedCall.isEnded) {
        _scheduleStateCleanup();
      }

      if (kDebugMode) {
        debugPrint('📊 CallManager: Call status updated: ${updatedCall.status.name}');
      }
    }
  }

  /// Clean up call state immediately
  Future<void> _cleanupCallState() async {
    if (kDebugMode) {
      debugPrint('🧹 CallManager: Cleaning up call state');
    }

    _callStateCleanupTimer?.cancel();
    
    final wasInCall = _isInCall;
    final hadCurrentCall = _currentCall != null;

    _currentCall = null;
    _isInCall = false;
    _isJoiningCall = false;

    // Notify listeners
    if (hadCurrentCall) {
      _currentCallController.add(null);
    }
    if (wasInCall) {
      _callStateController.add(false);
    }

    if (kDebugMode) {
      debugPrint('✅ CallManager: Call state cleaned up');
    }
  }

  /// Schedule state cleanup with a delay to handle race conditions
  void _scheduleStateCleanup() {
    _callStateCleanupTimer?.cancel();
    _callStateCleanupTimer = Timer(const Duration(seconds: 2), () {
      _cleanupCallState();
    });
  }

  /// Force cleanup for emergency situations
  Future<void> forceCleanup() async {
    if (kDebugMode) {
      debugPrint('🚨 CallManager: Force cleanup requested');
    }
    
    try {
      // Try to end any active call first
      final callService = ServiceLocator().callServiceOrNull;
      if (callService != null && _isInCall) {
        await callService.endCall();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ CallManager: Error during force cleanup: $e');
      }
    } finally {
      await _cleanupCallState();
    }
  }

  /// Dispose resources
  void dispose() {
    _callStateCleanupTimer?.cancel();
    _currentCallController.close();
    _callStateController.close();
  }
}