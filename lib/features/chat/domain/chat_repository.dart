import 'models/conversation_model.dart';
import 'models/message_model.dart';

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

  /// Send a message in a conversation
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
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

  /// Update message (for editing)
  Future<void> updateMessage(String conversationId, MessageModel message);

  /// Delete a message
  Future<void> deleteMessage(String conversationId, String messageId);

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

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId);
}