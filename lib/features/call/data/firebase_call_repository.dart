import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/call_model.dart';
import '../domain/repositories/call_repository.dart';
import '../../../core/config/agora_config.dart';

class FirebaseCallRepository implements CallRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _callsCollection = 'calls';

  @override
  Future<CallModel> initiateCall({
    required String callerId,
    required String receiverId,
    required CallType callType,
    required String callerName,
    required String callerPhotoUrl,
    required String receiverName,
    required String receiverPhotoUrl,
  }) async {
    try {
      // Generate unique call ID and channel name
      final callId = AgoraConfig.generateCallId();
      final channelName = AgoraConfig.generateChannelName(callerId, receiverId);

      // Create call model
      final call = CallModel.create(
        callId: callId,
        callerId: callerId,
        receiverId: receiverId,
        callType: callType,
        channelName: channelName,
        callerName: callerName,
        callerPhotoUrl: callerPhotoUrl,
        receiverName: receiverName,
        receiverPhotoUrl: receiverPhotoUrl,
      );

      // Save to Firestore
      await _firestore
          .collection(_callsCollection)
          .doc(callId)
          .set(call.toFirestore());

      if (kDebugMode) {
        print('📞 Call initiated: ${call.callId}');
      }

      return call;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initiating call: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateCallStatus(
    String callId, 
    CallStatus status, {
    DateTime? startedAt,
    DateTime? endedAt,
    CallEndReason? endReason,
    int? duration,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };

      if (startedAt != null) {
        updateData['startedAt'] = Timestamp.fromDate(startedAt);
      }

      if (endedAt != null) {
        updateData['endedAt'] = Timestamp.fromDate(endedAt);
      }

      if (endReason != null) {
        updateData['endReason'] = endReason.name;
      }

      if (duration != null) {
        updateData['duration'] = duration;
      }

      await _firestore
          .collection(_callsCollection)
          .doc(callId)
          .update(updateData);

      if (kDebugMode) {
        print('📞 Call status updated: $callId -> ${status.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating call status: $e');
      }
      rethrow;
    }
  }

  @override
  Future<CallModel?> getCall(String callId) async {
    try {
      final doc = await _firestore
          .collection(_callsCollection)
          .doc(callId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return CallModel.fromFirestore(doc.data()!);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting call: $e');
      }
      return null;
    }
  }

  @override
  Stream<CallModel?> listenToCall(String callId) {
    return _firestore
        .collection(_callsCollection)
        .doc(callId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return CallModel.fromFirestore(doc.data()!);
    });
  }

  @override
  Stream<List<CallModel>> listenToIncomingCalls(String userId) {
    return _firestore
        .collection(_callsCollection)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: CallStatus.ringing.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CallModel.fromFirestore(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<CallModel>> getCallHistory(String userId, {int limit = 50}) async {
    try {
      // Get calls where user is either caller or receiver
      final callerQuery = _firestore
          .collection(_callsCollection)
          .where('callerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final receiverQuery = _firestore
          .collection(_callsCollection)
          .where('receiverId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final [callerSnapshot, receiverSnapshot] = await Future.wait([
        callerQuery.get(),
        receiverQuery.get(),
      ]);

      // Combine and deduplicate results
      final allCalls = <String, CallModel>{};

      for (final doc in callerSnapshot.docs) {
        final call = CallModel.fromFirestore(doc.data());
        allCalls[call.callId] = call;
      }

      for (final doc in receiverSnapshot.docs) {
        final call = CallModel.fromFirestore(doc.data());
        allCalls[call.callId] = call;
      }

      // Sort by creation date and return
      final sortedCalls = allCalls.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return sortedCalls.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting call history: $e');
      }
      return [];
    }
  }

  @override
  Future<void> deleteCall(String callId) async {
    try {
      await _firestore
          .collection(_callsCollection)
          .doc(callId)
          .delete();

      if (kDebugMode) {
        print('📞 Call deleted: $callId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting call: $e');
      }
      rethrow;
    }
  }

  @override
  Future<CallModel?> getActiveCall(String userId) async {
    try {
      // Check for active calls where user is caller
      final callerQuery = await _firestore
          .collection(_callsCollection)
          .where('callerId', isEqualTo: userId)
          .where('status', whereIn: [
            CallStatus.initiating.name,
            CallStatus.connecting.name,
            CallStatus.connected.name,
          ])
          .limit(1)
          .get();

      if (callerQuery.docs.isNotEmpty) {
        return CallModel.fromFirestore(callerQuery.docs.first.data());
      }

      // Check for active calls where user is receiver
      final receiverQuery = await _firestore
          .collection(_callsCollection)
          .where('receiverId', isEqualTo: userId)
          .where('status', whereIn: [
            CallStatus.ringing.name,
            CallStatus.connecting.name,
            CallStatus.connected.name,
          ])
          .limit(1)
          .get();

      if (receiverQuery.docs.isNotEmpty) {
        return CallModel.fromFirestore(receiverQuery.docs.first.data());
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting active call: $e');
      }
      return null;
    }
  }

  @override
  Future<void> endCall(String callId, CallEndReason reason) async {
    try {
      await updateCallStatus(
        callId,
        CallStatus.ended,
        endedAt: DateTime.now(),
        endReason: reason,
      );

      if (kDebugMode) {
        print('📞 Call ended: $callId, reason: ${reason.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error ending call: $e');
      }
      rethrow;
    }
  }
}