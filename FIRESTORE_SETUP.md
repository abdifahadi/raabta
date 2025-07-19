# Firestore Setup for Messaging System

## Required Firestore Indexes

To ensure optimal query performance, create the following composite indexes in your Firestore console:

### Conversations Collection

1. **User Conversations Index**
   - Collection ID: `conversations`
   - Fields indexed:
     - `participants` (Array)
     - `updatedAt` (Descending)
   - Query scope: Collection

2. **Conversation Participants Index**
   - Collection ID: `conversations`
   - Fields indexed:
     - `participants` (Array)
     - `createdAt` (Descending)
   - Query scope: Collection

### Messages Subcollection

3. **Message Ordering Index**
   - Collection ID: `conversations/{conversationId}/messages`
   - Fields indexed:
     - `timestamp` (Descending)
   - Query scope: Collection group

4. **Message Search Index** (Optional - for text search)
   - Collection ID: `conversations/{conversationId}/messages`
   - Fields indexed:
     - `content` (Ascending)
     - `timestamp` (Descending)
   - Query scope: Collection group

## Creating Indexes via Firebase CLI

You can also create indexes programmatically using `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "conversations",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "participants",
          "arrayConfig": "CONTAINS"
        },
        {
          "fieldPath": "updatedAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        {
          "fieldPath": "timestamp",
          "order": "DESCENDING"
        }
      ]
    }
  ]
}
```

Deploy with:
```bash
firebase deploy --only firestore:indexes
```

## Security Rules

### Complete Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - profiles and authentication data
    match /users/{userId} {
      // Anyone authenticated can read user profiles
      allow read: if request.auth != null;
      
      // Only the user themselves can write to their profile
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Conversations collection
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
      
      // Prevent conversation deletion (optional - based on your business logic)
      allow delete: if false;
      
      // Messages subcollection
      match /messages/{messageId} {
        // Only conversation participants can read messages
        allow read: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
        
        // Only sender can create messages, and they must be a participant
        allow create: if request.auth != null && 
          request.auth.uid == request.resource.data.senderId &&
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
        
        // Only sender can update their own messages (for editing feature)
        allow update: if request.auth != null && 
          request.auth.uid == resource.data.senderId &&
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
        
        // Only sender can delete their own messages
        allow delete: if request.auth != null && 
          request.auth.uid == resource.data.senderId;
      }
    }
  }
}
```

### Rule Validation Functions

For more complex scenarios, you can add helper functions:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is conversation participant
    function isConversationParticipant(conversationId) {
      return request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
    }
    
    // Helper function to validate message data
    function isValidMessage() {
      return request.resource.data.keys().hasAll(['senderId', 'receiverId', 'content', 'timestamp', 'messageType']) &&
             request.resource.data.senderId == request.auth.uid &&
             request.resource.data.content is string &&
             request.resource.data.content.size() > 0 &&
             request.resource.data.content.size() <= 1000; // Max message length
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Conversations with helper functions
    match /conversations/{conversationId} {
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.participants;
      
      allow create, update: if request.auth != null && 
        request.auth.uid in request.resource.data.participants;
      
      match /messages/{messageId} {
        allow read: if request.auth != null && isConversationParticipant(conversationId);
        allow create: if request.auth != null && 
          isConversationParticipant(conversationId) && 
          isValidMessage();
        allow update: if request.auth != null && 
          request.auth.uid == resource.data.senderId;
        allow delete: if request.auth != null && 
          request.auth.uid == resource.data.senderId;
      }
    }
  }
}
```

## Testing Security Rules

Use the Firebase Console's Rules Playground to test your security rules:

### Test Cases

1. **Read Conversations**
   - Path: `/conversations/{conversationId}`
   - Auth: User who is a participant
   - Expected: Allow

2. **Read Messages**
   - Path: `/conversations/{conversationId}/messages/{messageId}`
   - Auth: User who is a participant
   - Expected: Allow

3. **Send Message**
   - Path: `/conversations/{conversationId}/messages/{messageId}`
   - Auth: Sender user
   - Data: Valid message object
   - Expected: Allow

4. **Read Other's Conversation**
   - Path: `/conversations/{conversationId}`
   - Auth: User who is NOT a participant
   - Expected: Deny

## Performance Considerations

### Query Optimization
- Always use indexed fields in queries
- Limit query results with `.limit()`
- Use cursor-based pagination for large datasets
- Consider denormalizing frequently accessed data

### Cost Optimization
- Use `orderBy` with indexed fields
- Avoid complex queries with multiple `where` clauses
- Implement proper pagination to reduce read costs
- Cache user profiles to reduce repeated reads

## Monitoring and Debugging

### Enable Firestore Debug Logging
```bash
# For web
localStorage.debug = 'firestore*'

# For Flutter
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### Monitor Performance
1. Use Firebase Console's Performance tab
2. Monitor query execution times
3. Check index usage statistics
4. Set up alerts for unusual activity

## Migration Considerations

If migrating from an existing system:

1. **Data Export**: Export existing messages/conversations
2. **Schema Mapping**: Map old schema to new ConversationModel/MessageModel
3. **Batch Import**: Use Firebase Admin SDK for bulk data import
4. **Gradual Migration**: Implement dual-write during transition period
5. **Validation**: Verify data integrity after migration

## Backup Strategy

### Automated Backups
```bash
# Schedule regular backups
gcloud firestore export gs://your-bucket-name/backups/$(date +%Y-%m-%d)
```

### Point-in-Time Recovery
- Enable point-in-time recovery in Firebase Console
- Retain backups for required compliance period
- Test restore procedures regularly

## Conclusion

This Firestore setup ensures optimal performance, security, and scalability for the messaging system. Regular monitoring and maintenance of indexes and rules will ensure continued optimal performance as your user base grows.