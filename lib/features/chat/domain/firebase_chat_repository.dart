import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_repository.dart';
import 'models/conversation_model.dart';
import 'models/message_model.dart';

/// Firebase implementation of ChatRepository
class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore;
  static const String _conversationsCollection = 'conversations';
  static const String _messagesSubcollection = 'messages';

  /// Constructor with dependency injection
  FirebaseChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get conversations collection reference
  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection(_conversationsCollection);

  /// Get messages collection reference for a conversation
  CollectionReference<Map<String, dynamic>> _getMessagesRef(String conversationId) =>
      _conversationsRef.doc(conversationId).collection(_messagesSubcollection);

  @override
  Stream<List<ConversationModel>> getUserConversations(String userId) {
    return _conversationsRef
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConversationModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      final doc = await _conversationsRef.doc(conversationId).get();
      if (doc.exists && doc.data() != null) {
        return ConversationModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  @override
  Future<ConversationModel> createConversation(String userId1, String userId2) async {
    try {
      final conversation = ConversationModel.create(
        userId1: userId1,
        userId2: userId2,
      );

      await _conversationsRef.doc(conversation.id).set(conversation.toMap());
      return conversation;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  @override
  Future<ConversationModel> getOrCreateConversation(String userId1, String userId2) async {
    try {
      final conversationId = ConversationModel.generateConversationId(userId1, userId2);
      
      // Check if conversation already exists
      final existingConversation = await getConversation(conversationId);
      if (existingConversation != null) {
        return existingConversation;
      }

      // Create new conversation
      return await createConversation(userId1, userId2);
    } catch (e) {
      throw Exception('Failed to get or create conversation: $e');
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create message
      final messagesRef = _getMessagesRef(conversationId);
      final messageDoc = messagesRef.doc();
      
      final message = MessageModel(
        id: messageDoc.id,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        messageType: messageType,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );

      // Use batch to ensure atomicity
      final batch = _firestore.batch();

      // Add message
      batch.set(messageDoc, message.toMap());

      // Update conversation
      final conversation = await getConversation(conversationId);
      if (conversation != null) {
        final updatedConversation = conversation.updateWithMessage(message);
        batch.update(_conversationsRef.doc(conversationId), updatedConversation.toMap());
      }

      await batch.commit();
      return message;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Stream<List<MessageModel>> getConversationMessages(String conversationId) {
    return _getMessagesRef(conversationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<List<MessageModel>> getConversationMessagesWithPagination({
    required String conversationId,
    int limit = 20,
    MessageModel? lastMessage,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _getMessagesRef(conversationId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastMessage != null) {
        query = query.startAfter([Timestamp.fromDate(lastMessage.timestamp)]);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages with pagination: $e');
    }
  }

  @override
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      final conversation = await getConversation(conversationId);
      if (conversation != null) {
        final updatedConversation = conversation.markAsRead(userId);
        await _conversationsRef.doc(conversationId).update(updatedConversation.toMap());
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  @override
  Future<void> updateMessage(String conversationId, MessageModel message) async {
    try {
      await _getMessagesRef(conversationId).doc(message.id).update(message.toMap());
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  @override
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      await _getMessagesRef(conversationId).doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  @override
  Future<List<MessageModel>> searchMessages({
    required String conversationId,
    required String query,
    int limit = 10,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that searches for exact matches
      // For production, consider using Algolia or Elastic Search
      final snapshot = await _getMessagesRef(conversationId)
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThan: '$query\uf8ff')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  @override
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final conversations = await _conversationsRef
          .where('participants', arrayContains: userId)
          .get();

      int totalUnreadCount = 0;
      for (final doc in conversations.docs) {
        final conversation = ConversationModel.fromMap(doc.data(), doc.id);
        totalUnreadCount += conversation.getUnreadCount(userId);
      }

      return totalUnreadCount;
    } catch (e) {
      throw Exception('Failed to get unread message count: $e');
    }
  }

  @override
  Future<void> updateConversationMetadata(
    String conversationId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      await _conversationsRef.doc(conversationId).update({
        'metadata': metadata,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update conversation metadata: $e');
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the conversation
      final messagesSnapshot = await _getMessagesRef(conversationId).get();
      final batch = _firestore.batch();

      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the conversation
      batch.delete(_conversationsRef.doc(conversationId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }
}