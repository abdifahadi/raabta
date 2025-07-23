import '../models/call_model.dart';

abstract class CallRepository {
  /// Initiate a new call
  Future<CallModel> initiateCall({
    required String callerId,
    required String receiverId,
    required CallType callType,
    required String callerName,
    required String callerPhotoUrl,
    required String receiverName,
    required String receiverPhotoUrl,
  });

  /// Update call status with additional metadata
  Future<void> updateCallStatus(
    String callId,
    CallStatus status, {
    DateTime? startedAt,
    DateTime? endedAt,
    CallEndReason? endReason,
    int? duration,
  });

  /// Get a specific call by ID
  Future<CallModel?> getCall(String callId);

  /// Get active call for a user (if any)
  Future<CallModel?> getActiveCall(String userId);

  /// Watch call changes in real-time
  Stream<CallModel?> watchCall(String callId);

  /// Watch for incoming calls for a user
  Stream<CallModel?> watchIncomingCalls(String userId);

  /// Get call history for a user
  Future<List<CallModel>> getCallHistory(String userId, {int limit = 50});

  /// Delete a call record
  Future<void> deleteCall(String callId);

  /// Stream call updates (alias for watchCall)
  Stream<CallModel?> getCallStream(String callId) => watchCall(callId);
  
  /// Listen to incoming calls (alias for watchIncomingCalls)
  Stream<CallModel?> listenToIncomingCalls(String userId) => watchIncomingCalls(userId);
}