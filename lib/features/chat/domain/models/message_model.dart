import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for different message types
enum MessageType {
  text,
  image,
  file,
  audio,
  video;

  String get value => name;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Model representing a chat message
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final MessageType messageType;
  final bool isRead;
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata; // For future use (file URLs, etc.)

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.messageType = MessageType.text,
    this.isRead = false,
    this.replyToMessageId,
    this.metadata,
  });

  /// Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'messageType': messageType.value,
      'isRead': isRead,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
    };
  }

  /// Create a MessageModel from a Firestore document
  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MessageModel(
      id: documentId,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      content: map['content'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      messageType: MessageType.fromString(map['messageType'] as String? ?? 'text'),
      isRead: map['isRead'] as bool? ?? false,
      replyToMessageId: map['replyToMessageId'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create a copy of this MessageModel with updated fields
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    MessageType? messageType,
    bool? isRead,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if this message was sent by the given user
  bool isSentBy(String userId) => senderId == userId;

  /// Check if this message was received by the given user
  bool isReceivedBy(String userId) => receiverId == userId;
}