# Group Chat Feature Integration Test Guide

## Overview
This document outlines how to test the newly implemented group chat feature in the Raabta messaging app.

## Components Implemented

### 1. Domain Models
- **GroupModel** (`lib/features/chat/domain/models/group_model.dart`)
  - Contains group information: id, name, photoUrl, members, adminIds, timestamps
  - Supports member management, admin operations, and message tracking
  - Includes factory methods for group creation and updates

### 2. Repository Layer
- **GroupChatRepository** (`lib/features/chat/domain/group_chat_repository.dart`)
  - Abstract interface defining group chat operations
  - Methods for CRUD operations, member management, and messaging

- **FirebaseGroupChatRepository** (`lib/features/chat/domain/firebase_group_chat_repository.dart`)
  - Firebase implementation using Firestore
  - Groups stored in `/groups/{groupId}` collection
  - Group messages stored in `/groups/{groupId}/messages` subcollection
  - Supports encryption and media messages

### 3. Extended Message Model
- **MessageModel** enhancements
  - Added `isGroupMessage`, `groupId`, and `isSentInGroup()` methods
  - Metadata field includes `conversationType: "group"` for group messages

### 4. UI Components

#### Group Creation Screen (`lib/features/chat/presentation/group_creation_screen.dart`)
- Form for group name and photo
- Member selection with checkboxes
- Photo upload functionality
- Real-time member preview

#### Group Chat Screen (`lib/features/chat/presentation/group_chat_screen.dart`)
- Similar to regular chat but shows sender names for group messages
- Member profile avatars for message senders
- Group info navigation
- Media sharing support

#### Group Info Screen (`lib/features/chat/presentation/group_info_screen.dart`)
- Group details editing (name, photo)
- Member management (add/remove members)
- Admin management (promote/demote members)
- Leave group functionality

#### Updated Conversations Screen
- Added tab view for "Chats" and "Groups"
- Group tiles show member count and last message
- Unread count badges for both chats and groups

### 5. Service Integration
- Updated `ServiceLocator` to include `GroupChatRepository`
- Dependency injection for all group chat components

## Testing Steps

### 1. Group Creation Test
```dart
// Test creating a new group
final group = GroupModel.create(
  name: 'Test Group',
  creatorId: 'user123',
  members: ['user456', 'user789'],
);

// Verify group properties
assert(group.name == 'Test Group');
assert(group.members.contains('user123')); // Creator is member
assert(group.adminIds.contains('user123')); // Creator is admin
assert(group.members.length == 3);
```

### 2. Member Management Test
```dart
// Test adding a member
final updatedGroup = group.addMember('user101');
assert(updatedGroup.members.contains('user101'));
assert(updatedGroup.members.length == 4);

// Test removing a member
final removedGroup = updatedGroup.removeMember('user456');
assert(!removedGroup.members.contains('user456'));
assert(removedGroup.members.length == 3);
```

### 3. Admin Management Test
```dart
// Test promoting a member to admin
final promotedGroup = group.addAdmin('user456');
assert(promotedGroup.isAdmin('user456'));

// Test demoting an admin (if not last admin)
final demotedGroup = promotedGroup.removeAdmin('user456');
assert(!demotedGroup.isAdmin('user456'));
```

### 4. Group Messaging Test
```dart
// Test sending group message
final message = await groupChatRepository.sendGroupMessage(
  groupId: group.id,
  senderId: 'user123',
  content: 'Hello group!',
  messageType: MessageType.text,
);

// Verify message properties
assert(message.isGroupMessage);
assert(message.groupId == group.id);
assert(message.receiverId == group.id); // Group ID as receiver
```

### 5. UI Navigation Test
1. Open Conversations screen
2. Navigate to Groups tab
3. Tap "Create Group" button
4. Fill group name and select members
5. Create group and verify it appears in Groups list
6. Tap group to open Group Chat screen
7. Send messages and verify sender names appear
8. Tap group info to manage members

### 6. Firestore Structure Verification
```
/groups/{groupId}
  - id: string
  - name: string
  - photoUrl: string?
  - members: string[]
  - adminIds: string[]
  - createdAt: timestamp
  - updatedAt: timestamp
  - lastMessage: string?
  - lastMessageSenderId: string?
  - lastMessageTimestamp: timestamp?
  - lastMessageType: string?
  - unreadCounts: map<string, number>
  - mutedBy: string[]
  - metadata: map?

/groups/{groupId}/messages/{messageId}
  - id: string
  - senderId: string
  - receiverId: string (groupId)
  - content: string
  - timestamp: timestamp
  - messageType: string
  - status: string
  - replyToMessageId: string?
  - metadata: map (includes conversationType: "group", groupId)
  - isEncrypted: boolean
  - encryptedContent: string?
```

## Security Considerations

### 1. Firestore Rules
```javascript
// Groups collection rules
match /groups/{groupId} {
  allow read, write: if request.auth != null && 
    request.auth.uid in resource.data.members;
  
  match /messages/{messageId} {
    allow read, write: if request.auth != null && 
      request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.members;
  }
}
```

### 2. Admin Permissions
- Only admins can edit group info (name, photo)
- Only admins can add/remove members
- Only admins can promote/demote other members
- Cannot remove the last admin from a group

### 3. Member Permissions
- All members can send messages
- All members can leave the group
- If the last admin leaves, another member is promoted

## Cross-Platform Compatibility

### Responsive Design Elements
- Adaptive layouts for different screen sizes
- Platform-specific UI components where appropriate
- Consistent behavior across Android, iOS, Web, and Desktop

### Media Handling
- Cross-platform media picker integration
- Optimized image compression
- Cloud storage for group photos and media messages

## Performance Optimizations

### 1. Lazy Loading
- Member profiles loaded on-demand
- Message pagination for large groups
- Cached user profiles to reduce API calls

### 2. Real-time Updates
- Firestore listeners for group changes
- Efficient unread count management
- Optimistic UI updates

### 3. Memory Management
- Proper disposal of controllers and listeners
- Image caching for group photos
- Stream subscription cleanup

## Error Handling

### 1. Network Errors
- Retry mechanisms for failed operations
- Offline support with local caching
- User-friendly error messages

### 2. Permission Errors
- Validation for admin operations
- Graceful handling of insufficient permissions
- Clear feedback to users

### 3. Data Validation
- Group name length limits
- Member count restrictions
- Media file size limits

## Accessibility

### 1. Screen Reader Support
- Semantic labels for all interactive elements
- Descriptive text for images and icons
- Proper focus management

### 2. Visual Accessibility
- High contrast colors
- Scalable text sizes
- Clear visual hierarchy

### 3. Input Accessibility
- Voice input support
- Keyboard navigation
- Touch target sizing

This comprehensive group chat implementation provides a scalable, secure, and user-friendly solution that maintains the existing app's architecture while adding powerful group communication features.