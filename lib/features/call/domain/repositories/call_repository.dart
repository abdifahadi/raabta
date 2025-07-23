import '../models/call_model.dart';

abstract class CallRepository {
  /// Initialize a new call
  Future<CallModel> initiateCall({
    required String callerId,
    required String receiverId,
    required CallType callType,
    required String callerName,
    required String callerPhotoUrl,
    required String receiverName,
    required String receiverPhotoUrl,
  });

  /// Update call status
  Future<void> updateCallStatus(String callId, CallStatus status, {
    DateTime? startedAt,
    DateTime? endedAt,
    CallEndReason? endReason,
    int? duration,
  });

  /// Get call by ID
  Future<CallModel?> getCall(String callId);

  /// Listen to call changes
  Stream<CallModel?> listenToCall(String callId);

  /// Get call stream for a user
  Stream<CallModel?> getCallStream(String userId);

  /// Listen to incoming calls for a user
  Stream<List<CallModel>> listenToIncomingCalls(String userId);

  /// Get call history for a user
  Future<List<CallModel>> getCallHistory(String userId, {int limit = 50});

  /// Delete call record
  Future<void> deleteCall(String callId);

  /// Check if user is in an active call
  Future<CallModel?> getActiveCall(String userId);

  /// End call
  Future<void> endCall(String callId, CallEndReason reason);
}