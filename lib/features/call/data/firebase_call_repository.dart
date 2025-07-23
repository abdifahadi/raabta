import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/call_model.dart';
import '../domain/repositories/call_repository.dart';
import '../../../core/config/agora_config.dart';

class FirebaseCallRepository implements CallRepository {
  static final FirebaseCallRepository _instance = FirebaseCallRepository._internal();
  factory FirebaseCallRepository() => _instance;
  FirebaseCallRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Real-time call streams
  final Map<String, StreamController<CallModel?>> _callStreamControllers = {};
  final Map<String, StreamSubscription> _callSubscriptions = {};

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
      final callId = _generateCallId();
      final channelName = AgoraConfig.generateChannelName(callerId, receiverId);
      
      final call = CallModel(
        callId: callId,
        callerId: callerId,
        receiverId: receiverId,
        channelName: channelName,
        callType: callType,
        status: CallStatus.calling,
        createdAt: DateTime.now(),
        callerName: callerName,
        callerPhotoUrl: callerPhotoUrl,
        receiverName: receiverName,
        receiverPhotoUrl: receiverPhotoUrl,
      );

      // Store in Firestore with server timestamp
      await _firestore.collection('calls').doc(callId).set({
        ...call.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Call initiated: $callId');
      }

      return call;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initiate call: $e');
      }
      throw Exception('Failed to initiate call: $e');
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
        'lastUpdated': FieldValue.serverTimestamp(),
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

      await _firestore.collection('calls').doc(callId).update(updateData);

      if (kDebugMode) {
        debugPrint('✅ Call status updated: $callId -> ${status.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to update call status: $e');
      }
      throw Exception('Failed to update call status: $e');
    }
  }

  @override
  Future<CallModel?> getCall(String callId) async {
    try {
      final doc = await _firestore.collection('calls').doc(callId).get();
      
      if (!doc.exists) {
        return null;
      }

      return CallModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get call: $e');
      }
      throw Exception('Failed to get call: $e');
    }
  }

  @override
  Future<CallModel?> getActiveCall(String userId) async {
    try {
      // Check for active calls where the user is either caller or receiver
      final query = await _firestore
          .collection('calls')
          .where('status', whereIn: [
            CallStatus.calling.name,
            CallStatus.ringing.name,
            CallStatus.accepted.name,
            CallStatus.connected.name,
          ])
          .where(Filter.or(
            Filter('callerId', isEqualTo: userId),
            Filter('receiverId', isEqualTo: userId),
          ))
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      return CallModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get active call: $e');
      }
      throw Exception('Failed to get active call: $e');
    }
  }

  @override
  Stream<CallModel?> watchCall(String callId) {
    // Create or reuse stream controller for this call
    if (!_callStreamControllers.containsKey(callId)) {
      _callStreamControllers[callId] = StreamController<CallModel?>.broadcast();
      
      // Set up Firestore listener
      _callSubscriptions[callId] = _firestore
          .collection('calls')
          .doc(callId)
          .snapshots()
          .listen(
            (snapshot) {
              try {
                if (!snapshot.exists) {
                  _callStreamControllers[callId]?.add(null);
                  return;
                }

                final call = CallModel.fromMap(snapshot.data()!, snapshot.id);
                _callStreamControllers[callId]?.add(call);
                
                if (kDebugMode) {
                  debugPrint('📡 Call status updated via stream: ${call.status.name}');
                }
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('❌ Error in call stream: $e');
                }
                _callStreamControllers[callId]?.addError(e);
              }
            },
            onError: (error) {
              if (kDebugMode) {
                debugPrint('❌ Call stream error: $error');
              }
              _callStreamControllers[callId]?.addError(error);
            },
          );
    }

    return _callStreamControllers[callId]!.stream;
  }

  @override
  Stream<CallModel?> watchIncomingCalls(String userId) {
    return _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: userId)
        .where('status', whereIn: [
          CallStatus.calling.name,
          CallStatus.ringing.name,
        ])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          try {
            if (snapshot.docs.isEmpty) {
              return null;
            }

            final doc = snapshot.docs.first;
            final call = CallModel.fromMap(doc.data(), doc.id);
            
            if (kDebugMode) {
              debugPrint('📞 Incoming call detected: ${call.callId}');
            }
            
            return call;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Error parsing incoming call: $e');
            }
            return null;
          }
        });
  }

  @override
  Future<void> deleteCall(String callId) async {
    try {
      // Update call status to deleted first for real-time sync
      await updateCallStatus(callId, CallStatus.ended);
      
      // Add a small delay to ensure real-time updates are processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Delete the document
      await _firestore.collection('calls').doc(callId).delete();
      
      // Clean up streams
      await _cleanupCallStream(callId);

      if (kDebugMode) {
        debugPrint('✅ Call deleted: $callId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to delete call: $e');
      }
      throw Exception('Failed to delete call: $e');
    }
  }

  @override
  Future<List<CallModel>> getCallHistory(String userId, {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('calls')
          .where(Filter.or(
            Filter('callerId', isEqualTo: userId),
            Filter('receiverId', isEqualTo: userId),
          ))
          .where('status', whereIn: [
            CallStatus.ended.name,
            CallStatus.missed.name,
            CallStatus.declined.name,
            CallStatus.cancelled.name,
            CallStatus.failed.name,
          ])
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => CallModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get call history: $e');
      }
      throw Exception('Failed to get call history: $e');
    }
  }

  /// Generate a unique call ID
  String _generateCallId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Clean up stream resources for a specific call
  Future<void> _cleanupCallStream(String callId) async {
    try {
      // Cancel subscription
      await _callSubscriptions[callId]?.cancel();
      _callSubscriptions.remove(callId);
      
      // Close and remove stream controller
      await _callStreamControllers[callId]?.close();
      _callStreamControllers.remove(callId);
      
      if (kDebugMode) {
        debugPrint('🧹 Cleaned up stream for call: $callId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cleaning up call stream: $e');
      }
    }
  }

  /// Clean up all streams and resources
  Future<void> dispose() async {
    try {
      // Cancel all subscriptions
      for (final subscription in _callSubscriptions.values) {
        await subscription.cancel();
      }
      _callSubscriptions.clear();
      
      // Close all stream controllers
      for (final controller in _callStreamControllers.values) {
        await controller.close();
      }
      _callStreamControllers.clear();
      
      if (kDebugMode) {
        debugPrint('🧹 Firebase call repository disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error disposing call repository: $e');
      }
    }
  }
}