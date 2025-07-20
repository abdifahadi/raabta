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

  /// Get display name for message type
  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Text';
      case MessageType.image:
        return 'Image';
      case MessageType.file:
        return 'File';
      case MessageType.audio:
        return 'Audio';
      case MessageType.video:
        return 'Video';
    }
  }

  /// Get icon for message type
  String get icon {
    switch (this) {
      case MessageType.text:
        return '💬';
      case MessageType.image:
        return '📷';
      case MessageType.file:
        return '📎';
      case MessageType.audio:
        return '🎵';
      case MessageType.video:
        return '🎬';
    }
  }
}

/// Enum for message delivery status
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  String get value => name;

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MessageStatus.sent,
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
  final MessageStatus status;
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata; // For media URLs, file info, etc.
  final bool isEncrypted;
  final String? encryptedContent;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.messageType = MessageType.text,
    this.status = MessageStatus.sent,
    this.replyToMessageId,
    this.metadata,
    this.isEncrypted = false,
    this.encryptedContent,
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
      'status': status.value,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
      'isEncrypted': isEncrypted,
      'encryptedContent': encryptedContent,
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
      status: MessageStatus.fromString(map['status'] as String? ?? 'sent'),
      replyToMessageId: map['replyToMessageId'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
      isEncrypted: map['isEncrypted'] as bool? ?? false,
      encryptedContent: map['encryptedContent'] as String?,
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
    MessageStatus? status,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    bool? isEncrypted,
    String? encryptedContent,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      status: status ?? this.status,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      encryptedContent: encryptedContent ?? this.encryptedContent,
    );
  }

  /// Check if this message was sent by the given user
  bool isSentBy(String userId) => senderId == userId;

  /// Check if this message was received by the given user
  bool isReceivedBy(String userId) => receiverId == userId;

  /// Check if this message has media content
  bool get hasMedia => messageType != MessageType.text;

  /// Get media URL from metadata
  String? get mediaUrl => metadata?['mediaUrl'] as String?;

  /// Get file name from metadata
  String? get fileName => metadata?['fileName'] as String?;

  /// Get file size from metadata
  int? get fileSize => metadata?['fileSize'] as int?;

  /// Get mime type from metadata
  String? get mimeType => metadata?['mimeType'] as String?;

  /// Get thumbnail URL from metadata (for videos)
  String? get thumbnailUrl => metadata?['thumbnailUrl'] as String?;

  /// Get duration from metadata (for audio/video)
  Duration? get duration {
    final durationMs = metadata?['durationMs'] as int?;
    return durationMs != null ? Duration(milliseconds: durationMs) : null;
  }

  /// Get image dimensions from metadata
  Map<String, double>? get imageDimensions {
    final width = metadata?['width'] as double?;
    final height = metadata?['height'] as double?;
    if (width != null && height != null) {
      return {'width': width, 'height': height};
    }
    return null;
  }

  /// Check if message is read
  bool get isRead => status == MessageStatus.read;

  /// Check if message is delivered
  bool get isDelivered => 
      status == MessageStatus.delivered || status == MessageStatus.read;

  /// Check if message failed to send
  bool get isFailed => status == MessageStatus.failed;

  /// Check if message is being sent
  bool get isSending => status == MessageStatus.sending;

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize == null) return '';
    
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;
    
    if (fileSize! >= gb) {
      return '${(fileSize! / gb).toStringAsFixed(1)} GB';
    } else if (fileSize! >= mb) {
      return '${(fileSize! / mb).toStringAsFixed(1)} MB';
    } else if (fileSize! >= kb) {
      return '${(fileSize! / kb).toStringAsFixed(1)} KB';
    } else {
      return '$fileSize B';
    }
  }

  /// Get preview text for the message
  String get previewText {
    switch (messageType) {
      case MessageType.text:
        return isEncrypted ? '🔒 Encrypted message' : content;
      case MessageType.image:
        return isEncrypted ? '🔒 Encrypted image' : '📷 Image';
      case MessageType.file:
        return isEncrypted ? '🔒 Encrypted file' : '📎 ${fileName ?? 'File'}';
      case MessageType.audio:
        return isEncrypted ? '🔒 Encrypted audio' : '🎵 Audio';
      case MessageType.video:
        return isEncrypted ? '🔒 Encrypted video' : '🎬 Video';
    }
  }

  /// Get the actual content to display (decrypted if encrypted)
  /// This method should be used by the UI to display message content
  String getDisplayContent({String? decryptionKey}) {
    if (!isEncrypted) {
      return content;
    }

    if (decryptionKey == null || encryptedContent == null) {
      return '🔒 Encrypted message (key not available)';
    }

    try {
      // Import encryption utils here to avoid circular dependencies
      // This will be handled by the repository layer in practice
      return content; // Placeholder - actual decryption handled by repository
    } catch (e) {
      return '🔒 Failed to decrypt message';
    }
  }

  /// Check if this message can be decrypted
  bool canDecrypt(String? decryptionKey) {
    return !isEncrypted || 
           (decryptionKey != null && encryptedContent != null);
  }
}