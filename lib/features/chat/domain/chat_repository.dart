import 'models/conversation_model.dart';
import 'models/message_model.dart';
import '../../../core/services/media_picker_service.dart';

/// Repository interface for chat operations
abstract class ChatRepository {
  /// Get all conversations for a user
  Stream<List<ConversationModel>> getUserConversations(String userId);

  /// Get a specific conversation by ID
  Future<ConversationModel?> getConversation(String conversationId);

  /// Create a new conversation between two users
  Future<ConversationModel> createConversation(String userId1, String userId2);

  /// Get or create a conversation between two users
  Future<ConversationModel> getOrCreateConversation(String userId1, String userId2);

  /// Send a text message in a conversation
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  });

  /// Send a media message in a conversation
  Future<MessageModel> sendMediaMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required PickedMediaFile mediaFile,
    String? caption,
    String? replyToMessageId,
    Function(double)? onUploadProgress,
  });

  /// Get messages for a conversation with real-time updates
  Stream<List<MessageModel>> getConversationMessages(String conversationId);

  /// Get messages for a conversation with pagination
  Future<List<MessageModel>> getConversationMessagesWithPagination({
    required String conversationId,
    int limit = 20,
    MessageModel? lastMessage,
  });

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId);

  /// Update message status (sent, delivered, read)
  Future<void> updateMessageStatus(
    String conversationId,
    String messageId,
    MessageStatus status,
  );

  /// Update message (for editing)
  Future<void> updateMessage(String conversationId, MessageModel message);

  /// Delete a message
  Future<void> deleteMessage(String conversationId, String messageId);

  /// Delete a message for current user only (hide message)
  Future<void> deleteMessageForUser(
    String conversationId,
    String messageId,
    String userId,
  );

  /// Search messages in a conversation
  Future<List<MessageModel>> searchMessages({
    required String conversationId,
    required String query,
    int limit = 10,
  });

  /// Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId);

  /// Update conversation metadata
  Future<void> updateConversationMetadata(
    String conversationId,
    Map<String, dynamic> metadata,
  );

  /// Mute conversation for a user
  Future<void> muteConversation(String conversationId, String userId);

  /// Unmute conversation for a user
  Future<void> unmuteConversation(String conversationId, String userId);

  /// Block conversation for a user
  Future<void> blockConversation(String conversationId, String userId);

  /// Unblock conversation for a user
  Future<void> unblockConversation(String conversationId, String userId);

  /// Clear chat for a user (delete all messages for this user)
  Future<void> clearChatForUser(String conversationId, String userId);

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId);

  /// Save FCM token for a user
  Future<void> saveFCMToken(String userId, String token);

  /// Remove FCM token for a user
  Future<void> removeFCMToken(String userId, String token);

  /// Get active FCM tokens for a user
  Future<List<String>> getFCMTokens(String userId);

  /// Clean up old FCM tokens
  Future<void> cleanupOldFCMTokens(String userId);
}