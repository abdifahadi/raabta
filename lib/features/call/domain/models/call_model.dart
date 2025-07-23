import 'package:cloud_firestore/cloud_firestore.dart';

enum CallType { audio, video }

enum CallStatus { 
  calling,       // Call is being initiated/outgoing call
  ringing,       // Call is ringing on receiver's end
  accepted,      // Call was accepted by receiver  
  connected,     // Call is active/in progress
  ended,         // Call has ended normally
  declined,      // Call was declined by receiver
  missed,        // Call was missed (timeout)
  failed,        // Call failed due to technical issues
  cancelled      // Call was cancelled by caller
}

enum CallEndReason {
  normal,        // Normal hang up
  declined,      // Call was declined
  missed,        // Call was missed
  networkError,  // Network issues
  permissionDenied, // Mic/camera permission denied
  timeout,       // Call timed out
  cancelled,     // Call was cancelled
  unknown        // Unknown reason
}

class CallModel {
  final String callId;
  final String callerId;
  final String receiverId;
  final CallType callType;
  final CallStatus status;
  final String channelName;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final CallEndReason? endReason;
  final int? duration; // Duration in seconds
  final Map<String, dynamic>? metadata;

  // Caller and receiver info
  final String callerName;
  final String callerPhotoUrl;
  final String receiverName;
  final String receiverPhotoUrl;

  const CallModel({
    required this.callId,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    required this.status,
    required this.channelName,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.endReason,
    this.duration,
    this.metadata,
    required this.callerName,
    required this.callerPhotoUrl,
    required this.receiverName,
    required this.receiverPhotoUrl,
  });

  /// Factory constructor to create a new call
  factory CallModel.create({
    required String callerId,
    required String receiverId,
    required CallType callType,
    required String channelName,
    required String callerName,
    required String callerPhotoUrl,
    required String receiverName,
    required String receiverPhotoUrl,
  }) {
    return CallModel(
      callId: DateTime.now().millisecondsSinceEpoch.toString(),
      callerId: callerId,
      receiverId: receiverId,
      callType: callType,
      status: CallStatus.calling,
      channelName: channelName,
      createdAt: DateTime.now(),
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
      receiverName: receiverName,
      receiverPhotoUrl: receiverPhotoUrl,
    );
  }

  // Copy with method for immutable updates
  CallModel copyWith({
    String? callId,
    String? callerId,
    String? receiverId,
    CallType? callType,
    CallStatus? status,
    String? channelName,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    CallEndReason? endReason,
    int? duration,
    Map<String, dynamic>? metadata,
    String? callerName,
    String? callerPhotoUrl,
    String? receiverName,
    String? receiverPhotoUrl,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      channelName: channelName ?? this.channelName,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      endReason: endReason ?? this.endReason,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
      callerName: callerName ?? this.callerName,
      callerPhotoUrl: callerPhotoUrl ?? this.callerPhotoUrl,
      receiverName: receiverName ?? this.receiverName,
      receiverPhotoUrl: receiverPhotoUrl ?? this.receiverPhotoUrl,
    );
  }

  // Convert to Map (general purpose)
  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'receiverId': receiverId,
      'callType': callType.name,
      'status': status.name,
      'channelName': channelName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'endedAt': endedAt?.millisecondsSinceEpoch,
      'endReason': endReason?.name,
      'duration': duration,
      'metadata': metadata,
      'callerName': callerName,
      'callerPhotoUrl': callerPhotoUrl,
      'receiverName': receiverName,
      'receiverPhotoUrl': receiverPhotoUrl,
    };
  }

  // Create from Map (general purpose)
  factory CallModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    return CallModel(
      callId: docId ?? data['callId'] as String,
      callerId: data['callerId'] as String,
      receiverId: data['receiverId'] as String,
      callType: CallType.values.firstWhere(
        (e) => e.name == data['callType'],
        orElse: () => CallType.audio,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CallStatus.ended,
      ),
      channelName: data['channelName'] as String,
      createdAt: _parseDateTime(data['createdAt']),
      startedAt: data['startedAt'] != null ? _parseDateTime(data['startedAt']) : null,
      endedAt: data['endedAt'] != null ? _parseDateTime(data['endedAt']) : null,
      endReason: data['endReason'] != null 
          ? CallEndReason.values.firstWhere(
              (e) => e.name == data['endReason'],
              orElse: () => CallEndReason.unknown,
            )
          : null,
      duration: data['duration'] as int?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      callerName: data['callerName'] as String,
      callerPhotoUrl: data['callerPhotoUrl'] as String,
      receiverName: data['receiverName'] as String,
      receiverPhotoUrl: data['receiverPhotoUrl'] as String,
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      return DateTime.now();
    }
  }

  // Convert to Firestore document (legacy support)
  Map<String, dynamic> toFirestore() {
    return {
      'callId': callId,
      'callerId': callerId,
      'receiverId': receiverId,
      'callType': callType.name,
      'status': status.name,
      'channelName': channelName,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'endReason': endReason?.name,
      'duration': duration,
      'metadata': metadata,
      'callerName': callerName,
      'callerPhotoUrl': callerPhotoUrl,
      'receiverName': receiverName,
      'receiverPhotoUrl': receiverPhotoUrl,
    };
  }

  // Create from Firestore document (legacy support)
  factory CallModel.fromFirestore(Map<String, dynamic> data) {
    return CallModel(
      callId: data['callId'] as String,
      callerId: data['callerId'] as String,
      receiverId: data['receiverId'] as String,
      callType: CallType.values.firstWhere(
        (e) => e.name == data['callType'],
        orElse: () => CallType.audio,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CallStatus.ended,
      ),
      channelName: data['channelName'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startedAt: data['startedAt'] != null 
          ? (data['startedAt'] as Timestamp).toDate() 
          : null,
      endedAt: data['endedAt'] != null 
          ? (data['endedAt'] as Timestamp).toDate() 
          : null,
      endReason: data['endReason'] != null 
          ? CallEndReason.values.firstWhere(
              (e) => e.name == data['endReason'],
              orElse: () => CallEndReason.unknown,
            )
          : null,
      duration: data['duration'] as int?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      callerName: data['callerName'] as String,
      callerPhotoUrl: data['callerPhotoUrl'] as String,
      receiverName: data['receiverName'] as String,
      receiverPhotoUrl: data['receiverPhotoUrl'] as String,
    );
  }

  // Helper methods
  bool get isActive => status == CallStatus.accepted || status == CallStatus.connected;
  bool get isEnded => status == CallStatus.ended || 
                     status == CallStatus.declined || 
                     status == CallStatus.missed ||
                     status == CallStatus.failed ||
                     status == CallStatus.cancelled;
  bool get isIncoming => status == CallStatus.ringing;
  bool get isOutgoing => status == CallStatus.calling;

  // Get formatted duration
  String get formattedDuration {
    if (duration == null) return '00:00';
    
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'CallModel(callId: $callId, callType: $callType, status: $status, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CallModel && other.callId == callId;
  }

  @override
  int get hashCode => callId.hashCode;
}