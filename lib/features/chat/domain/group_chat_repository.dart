import 'models/group_model.dart';
import 'models/message_model.dart';
import '../../../core/services/media_picker_service.dart';

/// Repository interface for group chat operations
abstract class GroupChatRepository {
  /// Create a new group
  Future<GroupModel> createGroup(GroupModel group);

  /// Get all groups for a user
  Stream<List<GroupModel>> getGroupsForUser(String userId);

  /// Get a specific group by ID
  Future<GroupModel?> getGroup(String groupId);

  /// Update group information (name, photo, etc.)
  Future<GroupModel> updateGroup(GroupModel updatedGroup);

  /// Delete a group (only admin can delete)
  Future<void> deleteGroup(String groupId);

  /// Add a member to a group
  Future<GroupModel> addMember(String groupId, String userId);

  /// Remove a member from a group
  Future<GroupModel> removeMember(String groupId, String userId);

  /// Add an admin to a group
  Future<GroupModel> addAdmin(String groupId, String userId);

  /// Remove an admin from a group
  Future<GroupModel> removeAdmin(String groupId, String userId);

  /// Send a text message to a group
  Future<MessageModel> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String content,
    MessageType messageType = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  });

  /// Send a media message to a group
  Future<MessageModel> sendGroupMediaMessage({
    required String groupId,
    required String senderId,
    required PickedMediaFile mediaFile,
    String? caption,
    String? replyToMessageId,
    Function(double)? onUploadProgress,
  });

  /// Get messages for a group with real-time updates
  Stream<List<MessageModel>> getGroupMessages(String groupId);

  /// Get messages for a group with pagination
  Future<List<MessageModel>> getGroupMessagesWithPagination({
    required String groupId,
    int limit = 20,
    MessageModel? lastMessage,
  });

  /// Mark group messages as read for a user
  Future<void> markGroupMessagesAsRead(String groupId, String userId);

  /// Mute/unmute a group for a user
  Future<void> muteGroup(String groupId, String userId, bool mute);

  /// Leave a group
  Future<void> leaveGroup(String groupId, String userId);

  /// Get group members information
  Future<List<String>> getGroupMembers(String groupId);

  /// Check if user is group admin
  Future<bool> isGroupAdmin(String groupId, String userId);

  /// Check if user is group member
  Future<bool> isGroupMember(String groupId, String userId);
}