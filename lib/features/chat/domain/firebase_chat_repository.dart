import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'chat_repository.dart';
import 'models/conversation_model.dart';
import 'models/message_model.dart';
import '../../../core/services/media_picker_service.dart';
import '../../../core/services/firebase_storage_repository.dart';
import '../../../core/services/encryption_key_manager.dart';
import '../../../core/utils/encryption_utils.dart';

/// Firebase implementation of ChatRepository
class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorageRepository _storageRepository;
  final EncryptionKeyManager _encryptionKeyManager;
  static const String _conversationsCollection = 'conversations';
  static const String _messagesSubcollection = 'messages';

  /// Constructor with dependency injection
  FirebaseChatRepository({
    FirebaseFirestore? firestore,
    FirebaseStorageRepository? storageRepository,
    EncryptionKeyManager? encryptionKeyManager,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageRepository = storageRepository ?? FirebaseStorageRepository(),
        _encryptionKeyManager = encryptionKeyManager ?? EncryptionKeyManager();

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
      
      // Check if encryption is enabled for this conversation
      final isEncrypted = _encryptionKeyManager.requiresEncryption(conversationId);
      String finalContent = content;
      String? encryptedContent;

      if (isEncrypted) {
        final encryptionKey = _encryptionKeyManager.getConversationKey(conversationId);
        if (encryptionKey != null) {
          // Encrypt the content
          encryptedContent = EncryptionUtils.encryptWithAES(content, encryptionKey);
          // For encrypted messages, store a placeholder in the content field
          finalContent = '🔒 Encrypted message';
        }
      }
      
      final message = MessageModel(
        id: messageDoc.id,
        senderId: senderId,
        receiverId: receiverId,
        content: finalContent,
        timestamp: DateTime.now(),
        messageType: messageType,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
        isEncrypted: isEncrypted,
        encryptedContent: encryptedContent,
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
  Future<MessageModel> sendMediaMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required PickedMediaFile mediaFile,
    String? caption,
    String? replyToMessageId,
    Function(double)? onUploadProgress,
  }) async {
    try {
      // Generate unique message ID first
      final messagesRef = _getMessagesRef(conversationId);
      final messageDoc = messagesRef.doc();
      final messageId = messageDoc.id;

      // Generate storage path
      final storagePath = _storageRepository.generateChatMediaPath(
        conversationId: conversationId,
        messageId: messageId,
        fileName: mediaFile.name,
      );

      // Upload media file
      String mediaUrl;
      if (mediaFile.file != null) {
        mediaUrl = await _storageRepository.uploadFile(
          path: storagePath,
          file: mediaFile.file!,
          fileName: mediaFile.name,
        );
      } else if (mediaFile.bytes != null) {
        mediaUrl = await _storageRepository.uploadBytes(
          path: storagePath,
          bytes: mediaFile.bytes!,
          fileName: mediaFile.name,
          mimeType: mediaFile.mimeType,
        );
      } else {
        throw Exception('No file or bytes provided');
      }

      // Determine message type from media type
      MessageType messageType;
      switch (mediaFile.type) {
        case MediaType.image:
          messageType = MessageType.image;
          break;
        case MediaType.video:
          messageType = MessageType.video;
          break;
        case MediaType.audio:
          messageType = MessageType.audio;
          break;
        case MediaType.document:
        case MediaType.any:
          messageType = MessageType.file;
          break;
      }

      // Create metadata
      final metadata = <String, dynamic>{
        'mediaUrl': mediaUrl,
        'fileName': mediaFile.name,
        'fileSize': mediaFile.size,
        'mimeType': mediaFile.mimeType,
      };

      // Add type-specific metadata
      if (mediaFile.extension != null) {
        metadata['extension'] = mediaFile.extension;
      }

      final message = MessageModel(
        id: messageId,
        senderId: senderId,
        receiverId: receiverId,
        content: caption ?? mediaFile.name,
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
      throw Exception('Failed to send media message: $e');
    }
  }

  @override
  Stream<List<MessageModel>> getConversationMessages(String conversationId) {
    return _getMessagesRef(conversationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final message = MessageModel.fromMap(doc.data(), doc.id);
            return _decryptMessageIfNeeded(message, conversationId);
          })
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
          .map((doc) {
            final message = MessageModel.fromMap(doc.data(), doc.id);
            return _decryptMessageIfNeeded(message, conversationId);
          })
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
  Future<void> updateMessageStatus(
    String conversationId,
    String messageId,
    MessageStatus status,
  ) async {
    try {
      await _getMessagesRef(conversationId).doc(messageId).update({
        'status': status.value,
      });
    } catch (e) {
      throw Exception('Failed to update message status: $e');
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
  Future<void> deleteMessageForUser(
    String conversationId,
    String messageId,
    String userId,
  ) async {
    try {
      // Add the user to deletedFor array in the message
      await _getMessagesRef(conversationId).doc(messageId).update({
        'deletedFor': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to delete message for user: $e');
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
  Future<void> muteConversation(String conversationId, String userId) async {
    try {
      await _conversationsRef.doc(conversationId).update({
        'mutedBy': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to mute conversation: $e');
    }
  }

  @override
  Future<void> unmuteConversation(String conversationId, String userId) async {
    try {
      await _conversationsRef.doc(conversationId).update({
        'mutedBy': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to unmute conversation: $e');
    }
  }

  @override
  Future<void> blockConversation(String conversationId, String userId) async {
    try {
      await _conversationsRef.doc(conversationId).update({
        'blockedBy': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to block conversation: $e');
    }
  }

  @override
  Future<void> unblockConversation(String conversationId, String userId) async {
    try {
      await _conversationsRef.doc(conversationId).update({
        'blockedBy': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to unblock conversation: $e');
    }
  }

  @override
  Future<void> clearChatForUser(String conversationId, String userId) async {
    try {
      // Get all messages and add userId to their deletedFor array
      final messagesSnapshot = await _getMessagesRef(conversationId).get();
      final batch = _firestore.batch();

      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {
          'deletedFor': FieldValue.arrayUnion([userId]),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear chat for user: $e');
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

  /// Save FCM token for a user
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      final tokenDoc = _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token);

      await tokenDoc.set({
        'token': token,
        'platform': _getCurrentPlatform(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsed': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save FCM token: $e');
    }
  }

  /// Remove FCM token for a user
  Future<void> removeFCMToken(String userId, String token) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to remove FCM token: $e');
    }
  }

  /// Get active FCM tokens for a user
  Future<List<String>> getFCMTokens(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['token'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to get FCM tokens: $e');
    }
  }

  /// Clean up old FCM tokens (older than 30 days)
  Future<void> cleanupOldFCMTokens(String userId) async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .where('lastUsed', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup old FCM tokens: $e');
    }
  }

  /// Get current platform string
  String _getCurrentPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  @override
  Future<String> enableEncryption(String conversationId) async {
    try {
      final key = _encryptionKeyManager.enableEncryption(conversationId);
      
      // Optional: Update conversation metadata to indicate encryption is enabled
      await updateConversationMetadata(conversationId, {
        'encryptionEnabled': true,
        'encryptionEnabledAt': FieldValue.serverTimestamp(),
      });
      
      return key;
    } catch (e) {
      throw Exception('Failed to enable encryption: $e');
    }
  }

  @override
  Future<void> disableEncryption(String conversationId) async {
    try {
      _encryptionKeyManager.disableEncryption(conversationId);
      
      // Optional: Update conversation metadata to indicate encryption is disabled
      await updateConversationMetadata(conversationId, {
        'encryptionEnabled': false,
        'encryptionDisabledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to disable encryption: $e');
    }
  }

  @override
  bool isEncryptionEnabled(String conversationId) {
    return _encryptionKeyManager.requiresEncryption(conversationId);
  }

  @override
  String getDecryptedContent(MessageModel message) {
    if (!message.isEncrypted) {
      return message.content;
    }

    if (message.encryptedContent == null) {
      return '🔒 Encrypted message (content not available)';
    }

    try {
      // This method would be called from the UI layer with the conversation ID
      // For now, we'll return a placeholder since we need the conversation context
      return '🔒 Encrypted message';
    } catch (e) {
      return '🔒 Failed to decrypt message';
    }
  }

  /// Decrypt message if needed (internal helper method)
  MessageModel _decryptMessageIfNeeded(MessageModel message, String conversationId) {
    if (!message.isEncrypted || message.encryptedContent == null) {
      return message;
    }

    final encryptionKey = _encryptionKeyManager.getConversationKey(conversationId);
    if (encryptionKey == null) {
      return message.copyWith(
        content: '🔒 Encrypted message (key not available)',
      );
    }

    try {
      final decryptedContent = EncryptionUtils.decryptWithAES(
        message.encryptedContent!,
        encryptionKey,
      );
      
      return message.copyWith(content: decryptedContent);
    } catch (e) {
      return message.copyWith(
        content: '🔒 Failed to decrypt message',
      );
    }
  }
}