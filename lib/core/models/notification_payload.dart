/// Notification payload model for FCM notifications
class NotificationPayload {
  final String? title;
  final String? body;
  final String? type;
  final String? conversationId;
  final String? senderId;
  final String? senderName;
  final String? messageId;
  final String? messageType;
  final Map<String, dynamic>? data;

  const NotificationPayload({
    this.title,
    this.body,
    this.type,
    this.conversationId,
    this.senderId,
    this.senderName,
    this.messageId,
    this.messageType,
    this.data,
  });

  /// Create from FCM RemoteMessage data
  factory NotificationPayload.fromMap(Map<String, dynamic> data) {
    return NotificationPayload(
      title: data['title'] as String?,
      body: data['body'] as String?,
      type: data['type'] as String?,
      conversationId: data['conversationId'] as String?,
      senderId: data['senderId'] as String?,
      senderName: data['senderName'] as String?,
      messageId: data['messageId'] as String?,
      messageType: data['messageType'] as String?,
      data: data,
    );
  }

  /// Convert to map for storage or transmission
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'messageId': messageId,
      'messageType': messageType,
      'data': data,
    };
  }

  /// Check if this is a chat message notification
  bool get isChatMessage => type == 'chat_message' && conversationId != null;

  /// Check if this is a system notification
  bool get isSystemNotification => type == 'system';

  @override
  String toString() {
    return 'NotificationPayload(title: $title, body: $body, type: $type, conversationId: $conversationId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationPayload &&
        other.title == title &&
        other.body == body &&
        other.type == type &&
        other.conversationId == conversationId &&
        other.senderId == senderId &&
        other.messageId == messageId;
  }

  @override
  int get hashCode {
    return Object.hash(
      title,
      body,
      type,
      conversationId,
      senderId,
      messageId,
    );
  }
}