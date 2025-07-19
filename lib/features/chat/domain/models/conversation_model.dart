import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart';

/// Model representing a conversation between two users
class ConversationModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTimestamp;
  final MessageType? lastMessageType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, int> unreadCounts; // userId -> unread count
  final Map<String, dynamic>? metadata;

  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTimestamp,
    this.lastMessageType,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCounts = const {},
    this.metadata,
  });

  /// Generate conversation ID from two user IDs
  static String generateConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Get the other participant's ID (not the current user)
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Check if a user is a participant in this conversation
  bool hasParticipant(String userId) {
    return participants.contains(userId);
  }

  /// Get unread count for a specific user
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  /// Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTimestamp': lastMessageTimestamp != null
          ? Timestamp.fromDate(lastMessageTimestamp!)
          : null,
      'lastMessageType': lastMessageType?.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadCounts': unreadCounts,
      'metadata': metadata,
    };
  }

  /// Create a ConversationModel from a Firestore document
  factory ConversationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ConversationModel(
      id: documentId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] as String?,
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      lastMessageTimestamp: map['lastMessageTimestamp'] != null
          ? (map['lastMessageTimestamp'] as Timestamp).toDate()
          : null,
      lastMessageType: map['lastMessageType'] != null
          ? MessageType.fromString(map['lastMessageType'] as String)
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create a copy of this ConversationModel with updated fields
  ConversationModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTimestamp,
    MessageType? lastMessageType,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, int>? unreadCounts,
    Map<String, dynamic>? metadata,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Create a new conversation between two users
  factory ConversationModel.create({
    required String userId1,
    required String userId2,
    Map<String, dynamic>? metadata,
  }) {
    final conversationId = generateConversationId(userId1, userId2);
    final now = DateTime.now();
    
    return ConversationModel(
      id: conversationId,
      participants: [userId1, userId2],
      createdAt: now,
      updatedAt: now,
      unreadCounts: {userId1: 0, userId2: 0},
      metadata: metadata,
    );
  }

  /// Update conversation with new message
  ConversationModel updateWithMessage(MessageModel message) {
    final newUnreadCounts = Map<String, int>.from(unreadCounts);
    
    // Increment unread count for receiver
    newUnreadCounts[message.receiverId] = (newUnreadCounts[message.receiverId] ?? 0) + 1;
    
    // Reset unread count for sender
    newUnreadCounts[message.senderId] = 0;

    return copyWith(
      lastMessage: message.content,
      lastMessageSenderId: message.senderId,
      lastMessageTimestamp: message.timestamp,
      lastMessageType: message.messageType,
      updatedAt: message.timestamp,
      unreadCounts: newUnreadCounts,
    );
  }

  /// Mark messages as read for a user
  ConversationModel markAsRead(String userId) {
    final newUnreadCounts = Map<String, int>.from(unreadCounts);
    newUnreadCounts[userId] = 0;
    
    return copyWith(
      unreadCounts: newUnreadCounts,
      updatedAt: DateTime.now(),
    );
  }
}