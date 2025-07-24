# Firestore Rules Setup for Raabta Call System

## Required Firestore Security Rules

Add the following rules to your Firestore project to enable the call system:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User authentication required for all operations
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // User can only access their own data
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Check if user is involved in the call (caller or receiver)
    function isCallParticipant(callData) {
      return isAuthenticated() && 
             (request.auth.uid == callData.callerId || 
              request.auth.uid == callData.receiverId);
    }
    
    // Call document rules
    match /calls/{callId} {
      // Allow read if user is participant in the call
      allow read: if isAuthenticated() && 
                     (resource.data.callerId == request.auth.uid || 
                      resource.data.receiverId == request.auth.uid);
      
      // Allow create if user is the caller
      allow create: if isAuthenticated() && 
                       request.auth.uid == resource.data.callerId;
      
      // Allow update if user is participant in the call
      allow update: if isAuthenticated() && 
                       (resource.data.callerId == request.auth.uid || 
                        resource.data.receiverId == request.auth.uid);
      
      // Allow delete if user is participant in the call  
      allow delete: if isAuthenticated() && 
                       (resource.data.callerId == request.auth.uid || 
                        resource.data.receiverId == request.auth.uid);
      
      // Call status subcollection
      match /status/{statusId} {
        allow read, write: if isAuthenticated() && 
                             (get(/databases/$(database)/documents/calls/$(callId)).data.callerId == request.auth.uid || 
                              get(/databases/$(database)/documents/calls/$(callId)).data.receiverId == request.auth.uid);
      }
    }
    
    // User profile rules
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }
    
    // User presence rules for call availability
    match /presence/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }
    
    // Chat rules (if needed for call history context)
    match /chats/{chatId} {
      allow read, write: if isAuthenticated() && 
                            request.auth.uid in resource.data.participants;
    }
  }
}
```

## Firestore Indexes Required

Add these indexes to your Firestore project:

### Call Queries Index
```
Collection: calls
Fields: receiverId (Ascending), status (Ascending), createdAt (Descending)
```

### Call History Index  
```
Collection: calls
Fields: callerId (Ascending), status (Ascending), createdAt (Descending)
```

### Incoming Calls Index
```
Collection: calls
Fields: receiverId (Ascending), status (Ascending)
```

## Setup Instructions

1. **Go to Firebase Console**
   - Navigate to your Firebase project
   - Go to Firestore Database section

2. **Update Security Rules**
   - Click on "Rules" tab
   - Replace the existing rules with the rules provided above
   - Click "Publish" to deploy the rules

3. **Create Indexes**
   - Go to "Indexes" tab  
   - Create the indexes listed above
   - Wait for indexes to build (may take a few minutes)

4. **Test the Rules**
   - Use the Firebase console simulator to test read/write operations
   - Ensure authenticated users can access call data correctly

## Rule Explanation

- **Authentication Required**: All operations require user authentication
- **Call Participants Only**: Users can only access calls where they are caller or receiver
- **Status Updates**: Both participants can update call status (accept, decline, end)
- **Call History**: Users can read their own call history
- **Real-time Updates**: Rules support real-time listeners for incoming calls

## Security Features

✅ **User Isolation**: Users can only access their own calls
✅ **Participant Validation**: Only call participants can modify call data  
✅ **Authentication Required**: All operations require valid Firebase Auth
✅ **Status Protection**: Call status can only be updated by participants
✅ **History Access**: Users can only see calls they participated in

## Troubleshooting

If you encounter permission errors:

1. Verify the user is authenticated in Firebase Auth
2. Check that the user ID matches callerId or receiverId in the call document
3. Ensure indexes are fully built
4. Test rules in Firebase Console simulator
5. Check Firebase console logs for detailed error messages

## Production Considerations

- Enable Firestore security monitoring
- Set up billing alerts for usage
- Monitor performance with Firebase Performance SDK
- Regular security rule audits
- Backup important call data if needed