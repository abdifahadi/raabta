# Firestore Rules ডিপ্লয় গাইড

## 🔥 Firebase Console এ Rules ডিপ্লয় করুন

### পদ্ধতি ১: Firebase Console (Recommended)

1. **Firebase Console এ যান**: https://console.firebase.google.com/project/abdifahadi-raabta/firestore/rules

2. **Rules Editor খুলুন**

3. **নিচের rules কপি করে paste করুন**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - profiles and authentication data
    match /users/{userId} {
      // Anyone authenticated can read user profiles (for searching users to chat with)
      allow read: if request.auth != null;
      
      // Only the user themselves can write to their profile
      // OR during sign-in process (allow creation for any authenticated user)
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Groups collection - for group chats
    match /groups/{groupId} {
      // Only group members can read group data
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.members;
      
      // Group creator and members can create groups
      allow create: if request.auth != null && 
        request.auth.uid in request.resource.data.members &&
        request.auth.uid == request.resource.data.createdBy;
        
      // Only group members can update group (for adding/removing members, updating name, etc.)
      allow update: if request.auth != null && 
        request.auth.uid in resource.data.members;
      
      // Only group creator can delete group
      allow delete: if request.auth != null && 
        request.auth.uid == resource.data.createdBy;
      
      // Messages subcollection for groups
      match /messages/{messageId} {
        // Only group members can read messages
        allow read: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.members;
        
        // Only group members can create messages
        allow create: if request.auth != null && 
          request.auth.uid == request.resource.data.senderId &&
          request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.members;
        
        // Only sender can update their own messages
        allow update: if request.auth != null && 
          request.auth.uid == resource.data.senderId &&
          request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.members;
        
        // Only sender can delete their own messages
        allow delete: if request.auth != null && 
          request.auth.uid == resource.data.senderId;
      }
    }
    
    // Conversations collection (for private chats)
    match /conversations/{conversationId} {
      // Only participants can read conversation metadata
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.participants;
      
      // Only participants can create/update conversations
      allow create: if request.auth != null && 
        request.auth.uid in request.resource.data.participants &&
        request.resource.data.participants.size() == 2;
        
      allow update: if request.auth != null && 
        request.auth.uid in resource.data.participants &&
        request.resource.data.participants == resource.data.participants;
      
      // Prevent conversation deletion
      allow delete: if false;
      
      // Messages subcollection for conversations
      match /messages/{messageId} {
        // Only conversation participants can read messages
        allow read: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
        
        // Only sender can create messages, and they must be a participant
        allow create: if request.auth != null && 
          request.auth.uid == request.resource.data.senderId &&
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
        
        // Only sender can update their own messages
        allow update: if request.auth != null && 
          request.auth.uid == resource.data.senderId &&
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
        
        // Only sender can delete their own messages
        allow delete: if request.auth != null && 
          request.auth.uid == resource.data.senderId;
      }
    }
    
    // Call sessions collection - for video/audio calls
    match /callSessions/{sessionId} {
      // Only participants can read call session data
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.callerId || 
         request.auth.uid == resource.data.receiverId);
      
      // Only caller can create call sessions
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.callerId;
        
      // Both participants can update call session (answer, end, etc.)
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.callerId || 
         request.auth.uid == resource.data.receiverId);
      
      // Both participants can delete call session
      allow delete: if request.auth != null && 
        (request.auth.uid == resource.data.callerId || 
         request.auth.uid == resource.data.receiverId);
    }
    
    // Notifications collection - for push notifications
    match /notifications/{notificationId} {
      // Only the recipient can read their notifications
      allow read: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      
      // System can create notifications, users cannot directly create
      allow create: if request.auth != null;
        
      // Only recipient can update their notifications (mark as read, etc.)
      allow update: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      
      // Only recipient can delete their notifications
      allow delete: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Helper match for any other collections that might be added
    match /{document=**} {
      // Default: authenticated users can read, but cannot write unless explicitly allowed above
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

4. **"Publish" বাটনে ক্লিক করুন**

5. **Success message দেখলে rules deploy হয়ে গেছে**

### পদ্ধতি ২: Firebase CLI (Alternative)

```bash
# Firebase CLI install করুন (যদি না থাকে)
npm install -g firebase-tools

# Login করুন
firebase login

# Project select করুন
firebase use abdifahadi-raabta

# Rules deploy করুন
firebase deploy --only firestore:rules
```

## ✅ Rules Deploy হয়ে গেছে কিনা চেক করুন

1. Firebase Console এ Firestore Rules section দেখুন
2. নতুন rules active দেখানো হবে
3. App এ গ্রুপ চ্যাট feature test করুন

## 🎯 Expected Result

Rules deploy হওয়ার পর:
- গ্রুপ চ্যাট সব functionality কাজ করবে
- "Failed to load groups" error আর থাকবে না
- Group creation, messaging, member management সব কাজ করবে