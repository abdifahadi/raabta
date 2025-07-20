import 'package:cloud_firestore/cloud_firestore.dart';
import 'group_chat_repository.dart';
import 'models/group_model.dart';
import 'models/message_model.dart';
import '../../../core/services/media_picker_service.dart';
import '../../../core/services/firebase_storage_repository.dart';
import '../../../core/services/encryption_key_manager.dart';
import '../../../core/utils/encryption_utils.dart';

/// Firebase implementation of GroupChatRepository
class FirebaseGroupChatRepository implements GroupChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorageRepository _storageRepository;
  final EncryptionKeyManager _encryptionKeyManager;
  static const String _groupsCollection = 'groups';
  static const String _messagesSubcollection = 'messages';

  /// Constructor with dependency injection
  FirebaseGroupChatRepository({
    FirebaseFirestore? firestore,
    FirebaseStorageRepository? storageRepository,
    EncryptionKeyManager? encryptionKeyManager,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageRepository = storageRepository ?? FirebaseStorageRepository(),
        _encryptionKeyManager = encryptionKeyManager ?? EncryptionKeyManager();

  /// Get groups collection reference
  CollectionReference<Map<String, dynamic>> get _groupsRef =>
      _firestore.collection(_groupsCollection);

  /// Get messages collection reference for a group
  CollectionReference<Map<String, dynamic>> _getGroupMessagesRef(String groupId) =>
      _groupsRef.doc(groupId).collection(_messagesSubcollection);

  @override
  Future<GroupModel> createGroup(GroupModel group) async {
    try {
      await _groupsRef.doc(group.id).set(group.toMap());
      return group;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  @override
  Stream<List<GroupModel>> getGroupsForUser(String userId) {
    return _groupsRef
        .where('members', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GroupModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _groupsRef.doc(groupId).get();
      if (doc.exists && doc.data() != null) {
        return GroupModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get group: $e');
    }
  }

  @override
  Future<GroupModel> updateGroup(GroupModel updatedGroup) async {
    try {
      await _groupsRef.doc(updatedGroup.id).update(updatedGroup.toMap());
      return updatedGroup;
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    try {
      // Use batch to delete group and all its messages
      final batch = _firestore.batch();
      
      // Delete all messages in the group
      final messagesSnapshot = await _getGroupMessagesRef(groupId).get();
      for (final messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }
      
      // Delete the group document
      batch.delete(_groupsRef.doc(groupId));
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  @override
  Future<GroupModel> addMember(String groupId, String userId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      final updatedGroup = group.addMember(userId);
      return await updateGroup(updatedGroup);
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  @override
  Future<GroupModel> removeMember(String groupId, String userId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      final updatedGroup = group.removeMember(userId);
      return await updateGroup(updatedGroup);
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  @override
  Future<GroupModel> addAdmin(String groupId, String userId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      final updatedGroup = group.addAdmin(userId);
      return await updateGroup(updatedGroup);
    } catch (e) {
      throw Exception('Failed to add admin: $e');
    }
  }

  @override
  Future<GroupModel> removeAdmin(String groupId, String userId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      final updatedGroup = group.removeAdmin(userId);
      return await updateGroup(updatedGroup);
    } catch (e) {
      throw Exception('Failed to remove admin: $e');
    }
  }

  @override
  Future<MessageModel> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String content,
    MessageType messageType = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create message
      final messagesRef = _getGroupMessagesRef(groupId);
      final messageDoc = messagesRef.doc();
      
      // Check if encryption is enabled for this group
      final isEncrypted = _encryptionKeyManager.requiresEncryption(groupId);
      String finalContent = content;
      String? encryptedContent;

      if (isEncrypted) {
        final encryptionKey = _encryptionKeyManager.getConversationKey(groupId);
        if (encryptionKey != null) {
          // Encrypt the content
          encryptedContent = EncryptionUtils.encryptWithAES(content, encryptionKey);
          // For encrypted messages, store a placeholder in the content field
          finalContent = '🔒 Encrypted message';
        }
      }
      
      // For group messages, receiverId is set to the groupId to distinguish from direct messages
      final message = MessageModel(
        id: messageDoc.id,
        senderId: senderId,
        receiverId: groupId, // Use groupId as receiverId for group messages
        content: finalContent,
        timestamp: DateTime.now(),
        messageType: messageType,
        replyToMessageId: replyToMessageId,
        metadata: {
          ...?metadata,
          'conversationType': 'group', // Mark as group message
          'groupId': groupId,
        },
        isEncrypted: isEncrypted,
        encryptedContent: encryptedContent,
      );

      // Use batch to ensure atomicity
      final batch = _firestore.batch();

      // Add message
      batch.set(messageDoc, message.toMap());

      // Update group with last message info
      final group = await getGroup(groupId);
      if (group != null) {
        final updatedGroup = group.updateWithMessage(
          finalContent,
          senderId,
          messageType.value,
        );
        batch.update(_groupsRef.doc(groupId), updatedGroup.toMap());
      }

      await batch.commit();
      return message;
    } catch (e) {
      throw Exception('Failed to send group message: $e');
    }
  }

  @override
  Future<MessageModel> sendGroupMediaMessage({
    required String groupId,
    required String senderId,
    required PickedMediaFile mediaFile,
    String? caption,
    String? replyToMessageId,
    Function(double)? onUploadProgress,
  }) async {
    try {
      // Generate unique message ID first
      final messagesRef = _getGroupMessagesRef(groupId);
      final messageDoc = messagesRef.doc();
      final messageId = messageDoc.id;

      // Generate storage path
      final storagePath = _storageRepository.generateChatMediaPath(
        conversationId: groupId,
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
      if (mediaFile.type == MediaType.image) {
        messageType = MessageType.image;
      } else if (mediaFile.type == MediaType.video) {
        messageType = MessageType.video;
      } else if (mediaFile.type == MediaType.audio) {
        messageType = MessageType.audio;
      } else {
        messageType = MessageType.file;
      }

      // Create metadata
      final metadata = <String, dynamic>{
        'mediaUrl': mediaUrl,
        'fileName': mediaFile.name,
        'fileSize': mediaFile.size,
        'mimeType': mediaFile.mimeType,
        'conversationType': 'group',
        'groupId': groupId,
      };

      // Add dimensions for images
      if (mediaFile.type == MediaType.image && 
          mediaFile.width != null && 
          mediaFile.height != null) {
        metadata['width'] = mediaFile.width!.toDouble();
        metadata['height'] = mediaFile.height!.toDouble();
      }

      // Add duration for audio/video
      if (mediaFile.duration != null) {
        metadata['durationMs'] = mediaFile.duration!;
      }

      // Send message with media metadata
      return await sendGroupMessage(
        groupId: groupId,
        senderId: senderId,
        content: caption ?? messageType.displayName,
        messageType: messageType,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );
    } catch (e) {
      throw Exception('Failed to send group media message: $e');
    }
  }

  @override
  Stream<List<MessageModel>> getGroupMessages(String groupId) {
    return _getGroupMessagesRef(groupId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<List<MessageModel>> getGroupMessagesWithPagination({
    required String groupId,
    int limit = 20,
    MessageModel? lastMessage,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _getGroupMessagesRef(groupId)
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
      throw Exception('Failed to get group messages with pagination: $e');
    }
  }

  @override
  Future<void> markGroupMessagesAsRead(String groupId, String userId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      final updatedGroup = group.markAsRead(userId);
      await updateGroup(updatedGroup);
    } catch (e) {
      throw Exception('Failed to mark group messages as read: $e');
    }
  }

  @override
  Future<void> muteGroup(String groupId, String userId, bool mute) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      final updatedGroup = mute 
          ? group.muteFor(userId)
          : group.unmuteFor(userId);
      
      await updateGroup(updatedGroup);
    } catch (e) {
      throw Exception('Failed to mute/unmute group: $e');
    }
  }

  @override
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      // If the user is the only admin, promote another member to admin first
      if (group.isAdmin(userId) && group.adminIds.length == 1 && group.members.length > 1) {
        // Find the first non-admin member and make them admin
        final newAdmin = group.members.firstWhere(
          (memberId) => memberId != userId,
          orElse: () => '',
        );
        
        if (newAdmin.isNotEmpty) {
          final groupWithNewAdmin = group.addAdmin(newAdmin);
          await updateGroup(groupWithNewAdmin);
        }
      }

      // Remove the user from the group
      await removeMember(groupId, userId);

      // If no members left, delete the group
      final updatedGroup = await getGroup(groupId);
      if (updatedGroup != null && updatedGroup.members.isEmpty) {
        await deleteGroup(groupId);
      }
    } catch (e) {
      throw Exception('Failed to leave group: $e');
    }
  }

  @override
  Future<List<String>> getGroupMembers(String groupId) async {
    try {
      final group = await getGroup(groupId);
      return group?.members ?? [];
    } catch (e) {
      throw Exception('Failed to get group members: $e');
    }
  }

  @override
  Future<bool> isGroupAdmin(String groupId, String userId) async {
    try {
      final group = await getGroup(groupId);
      return group?.isAdmin(userId) ?? false;
    } catch (e) {
      throw Exception('Failed to check admin status: $e');
    }
  }

  @override
  Future<bool> isGroupMember(String groupId, String userId) async {
    try {
      final group = await getGroup(groupId);
      return group?.isMember(userId) ?? false;
    } catch (e) {
      throw Exception('Failed to check member status: $e');
    }
  }
}