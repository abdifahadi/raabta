import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a group chat
class GroupModel {
  final String id;
  final String name;
  final String? photoUrl;
  final List<String> members;
  final List<String> adminIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTimestamp;
  final String? lastMessageType;
  final Map<String, int> unreadCounts; // userId -> unread count
  final List<String> mutedBy; // List of user IDs who muted this group
  final Map<String, dynamic>? metadata;

  GroupModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.members,
    required this.adminIds,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTimestamp,
    this.lastMessageType,
    this.unreadCounts = const {},
    this.mutedBy = const [],
    this.metadata,
  });

  /// Check if a user is an admin of this group
  bool isAdmin(String userId) {
    return adminIds.contains(userId);
  }

  /// Check if a user is a member of this group
  bool isMember(String userId) {
    return members.contains(userId);
  }

  /// Get unread count for a specific user
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  /// Check if group is muted by a user
  bool isMutedBy(String userId) {
    return mutedBy.contains(userId);
  }

  /// Get last message preview text
  String get lastMessagePreview {
    if (lastMessage == null) return 'No messages yet';
    
    switch (lastMessageType) {
      case 'text':
        return lastMessage!;
      case 'image':
        return '📷 Photo';
      case 'file':
        return '📎 File';
      case 'audio':
        return '🎵 Audio';
      case 'video':
        return '🎬 Video';
      default:
        return lastMessage!;
    }
  }

  /// Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'members': members,
      'adminIds': adminIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTimestamp': lastMessageTimestamp != null
          ? Timestamp.fromDate(lastMessageTimestamp!)
          : null,
      'lastMessageType': lastMessageType,
      'unreadCounts': unreadCounts,
      'mutedBy': mutedBy,
      'metadata': metadata,
    };
  }

  /// Create a GroupModel from a Firestore document
  factory GroupModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GroupModel(
      id: documentId,
      name: map['name'] as String,
      photoUrl: map['photoUrl'] as String?,
      members: List<String>.from(map['members'] ?? []),
      adminIds: List<String>.from(map['adminIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      lastMessage: map['lastMessage'] as String?,
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      lastMessageTimestamp: map['lastMessageTimestamp'] != null
          ? (map['lastMessageTimestamp'] as Timestamp).toDate()
          : null,
      lastMessageType: map['lastMessageType'] as String?,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      mutedBy: List<String>.from(map['mutedBy'] ?? []),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create a copy of this GroupModel with updated fields
  GroupModel copyWith({
    String? id,
    String? name,
    String? photoUrl,
    List<String>? members,
    List<String>? adminIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTimestamp,
    String? lastMessageType,
    Map<String, int>? unreadCounts,
    List<String>? mutedBy,
    Map<String, dynamic>? metadata,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      members: members ?? this.members,
      adminIds: adminIds ?? this.adminIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      mutedBy: mutedBy ?? this.mutedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Create a new group
  factory GroupModel.create({
    required String name,
    required String creatorId,
    String? photoUrl,
    List<String> members = const [],
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final groupId = 'group_${now.millisecondsSinceEpoch}_$creatorId';
    
    // Creator is always a member and admin
    final allMembers = [creatorId, ...members.where((id) => id != creatorId)];
    final unreadCounts = <String, int>{};
    for (final memberId in allMembers) {
      unreadCounts[memberId] = 0;
    }
    
    return GroupModel(
      id: groupId,
      name: name,
      photoUrl: photoUrl,
      members: allMembers,
      adminIds: [creatorId], // Creator is the initial admin
      createdAt: now,
      updatedAt: now,
      unreadCounts: unreadCounts,
      metadata: metadata,
    );
  }

  /// Add a member to the group
  GroupModel addMember(String userId) {
    if (isMember(userId)) return this;
    
    final newMembers = List<String>.from(members)..add(userId);
    final newUnreadCounts = Map<String, int>.from(unreadCounts);
    newUnreadCounts[userId] = 0;
    
    return copyWith(
      members: newMembers,
      unreadCounts: newUnreadCounts,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove a member from the group
  GroupModel removeMember(String userId) {
    if (!isMember(userId)) return this;
    
    final newMembers = List<String>.from(members)..remove(userId);
    final newAdminIds = List<String>.from(adminIds)..remove(userId);
    final newUnreadCounts = Map<String, int>.from(unreadCounts);
    newUnreadCounts.remove(userId);
    final newMutedBy = List<String>.from(mutedBy)..remove(userId);
    
    return copyWith(
      members: newMembers,
      adminIds: newAdminIds,
      unreadCounts: newUnreadCounts,
      mutedBy: newMutedBy,
      updatedAt: DateTime.now(),
    );
  }

  /// Add an admin to the group
  GroupModel addAdmin(String userId) {
    if (!isMember(userId) || isAdmin(userId)) return this;
    
    final newAdminIds = List<String>.from(adminIds)..add(userId);
    
    return copyWith(
      adminIds: newAdminIds,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove an admin from the group
  GroupModel removeAdmin(String userId) {
    if (!isAdmin(userId)) return this;
    
    // Ensure at least one admin remains
    if (adminIds.length <= 1) {
      throw Exception('Cannot remove the last admin from the group');
    }
    
    final newAdminIds = List<String>.from(adminIds)..remove(userId);
    
    return copyWith(
      adminIds: newAdminIds,
      updatedAt: DateTime.now(),
    );
  }

  /// Update group with new message
  GroupModel updateWithMessage(String content, String senderId, String messageType) {
    final newUnreadCounts = Map<String, int>.from(unreadCounts);
    
    // Increment unread count for all members except sender
    for (final memberId in members) {
      if (memberId != senderId && !isMutedBy(memberId)) {
        newUnreadCounts[memberId] = (newUnreadCounts[memberId] ?? 0) + 1;
      }
    }
    
    // Reset unread count for sender
    newUnreadCounts[senderId] = 0;

    return copyWith(
      lastMessage: content,
      lastMessageSenderId: senderId,
      lastMessageTimestamp: DateTime.now(),
      lastMessageType: messageType,
      updatedAt: DateTime.now(),
      unreadCounts: newUnreadCounts,
    );
  }

  /// Mark messages as read for a user
  GroupModel markAsRead(String userId) {
    final newUnreadCounts = Map<String, int>.from(unreadCounts);
    newUnreadCounts[userId] = 0;
    
    return copyWith(
      unreadCounts: newUnreadCounts,
      updatedAt: DateTime.now(),
    );
  }

  /// Mute group for a user
  GroupModel muteFor(String userId) {
    if (isMutedBy(userId)) return this;
    
    final newMutedBy = List<String>.from(mutedBy)..add(userId);
    
    return copyWith(
      mutedBy: newMutedBy,
      updatedAt: DateTime.now(),
    );
  }

  /// Unmute group for a user
  GroupModel unmuteFor(String userId) {
    if (!isMutedBy(userId)) return this;
    
    final newMutedBy = List<String>.from(mutedBy)..remove(userId);
    
    return copyWith(
      mutedBy: newMutedBy,
      updatedAt: DateTime.now(),
    );
  }

  /// Update group info (name, photo)
  GroupModel updateInfo({
    String? name,
    String? photoUrl,
  }) {
    return copyWith(
      name: name ?? this.name,
      photoUrl: photoUrl,
      updatedAt: DateTime.now(),
    );
  }
}