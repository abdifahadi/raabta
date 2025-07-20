# 🔔 Server-Side Push Notification Integration

## Overview

This document provides examples of how to send push notifications from your server-side application to the Raabta Flutter app using Firebase Cloud Messaging (FCM).

## 🚀 Firebase Admin SDK Setup

### Node.js Example

```javascript
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'your-project-id'
});

const messaging = admin.messaging();
```

### Python Example

```python
import firebase_admin
from firebase_admin import credentials, messaging

# Initialize Firebase Admin SDK
cred = credentials.Certificate('path/to/serviceAccountKey.json')
firebase_admin.initialize_app(cred)
```

## 📨 Sending Chat Message Notifications

### Single Device Notification

```javascript
// Node.js
async function sendChatNotification(recipientToken, senderName, messageContent, conversationId, senderId, messageId) {
  const message = {
    token: recipientToken,
    notification: {
      title: senderName,
      body: messageContent.length > 100 ? 
        messageContent.substring(0, 100) + '...' : 
        messageContent
    },
    data: {
      type: 'chat_message',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      messageId: messageId,
      messageType: 'text',
      timestamp: Date.now().toString()
    },
    android: {
      notification: {
        icon: 'ic_notification',
        color: '#673AB7',
        sound: 'default',
        channelId: 'raabta_messages'
      },
      priority: 'high'
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: senderName,
            body: messageContent.length > 100 ? 
              messageContent.substring(0, 100) + '...' : 
              messageContent
          },
          badge: 1,
          sound: 'default'
        }
      }
    },
    webpush: {
      notification: {
        title: senderName,
        body: messageContent.length > 100 ? 
          messageContent.substring(0, 100) + '...' : 
          messageContent,
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-72.png',
        tag: conversationId,
        requireInteraction: true
      }
    }
  };

  try {
    const response = await messaging.send(message);
    console.log('Successfully sent message:', response);
    return response;
  } catch (error) {
    console.log('Error sending message:', error);
    throw error;
  }
}
```

### Multiple Device Notification (Same User)

```javascript
// Send to all user's devices
async function sendChatNotificationToUser(userId, senderName, messageContent, conversationId, senderId, messageId) {
  // Get all active FCM tokens for the user from Firestore
  const userTokensRef = admin.firestore()
    .collection('users')
    .doc(userId)
    .collection('fcmTokens')
    .where('isActive', '==', true);
    
  const tokensSnapshot = await userTokensRef.get();
  const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
  
  if (tokens.length === 0) {
    console.log('No active tokens found for user:', userId);
    return;
  }

  const message = {
    tokens: tokens,
    notification: {
      title: senderName,
      body: messageContent.length > 100 ? 
        messageContent.substring(0, 100) + '...' : 
        messageContent
    },
    data: {
      type: 'chat_message',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      messageId: messageId,
      messageType: 'text',
      timestamp: Date.now().toString()
    }
  };

  try {
    const response = await messaging.sendMulticast(message);
    console.log('Successfully sent message to', response.successCount, 'devices');
    
    // Handle failed tokens (cleanup invalid tokens)
    if (response.failureCount > 0) {
      await cleanupFailedTokens(response.responses, tokens, userId);
    }
    
    return response;
  } catch (error) {
    console.log('Error sending multicast message:', error);
    throw error;
  }
}
```

### Media Message Notifications

```javascript
async function sendMediaNotification(recipientToken, senderName, mediaType, conversationId, senderId, messageId) {
  const mediaMessages = {
    image: '📷 Photo',
    video: '🎥 Video',
    audio: '🎵 Voice message',
    document: '📄 Document'
  };

  const message = {
    token: recipientToken,
    notification: {
      title: senderName,
      body: mediaMessages[mediaType] || '📎 Media'
    },
    data: {
      type: 'chat_message',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      messageId: messageId,
      messageType: mediaType,
      timestamp: Date.now().toString()
    }
  };

  return await messaging.send(message);
}
```

## 🔄 Firestore Triggers Integration

### Cloud Function Example

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Trigger on new message creation
exports.sendMessageNotification = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const conversationId = context.params.conversationId;
    const messageId = context.params.messageId;
    
    // Don't send notification for own messages
    const senderId = message.senderId;
    const receiverId = message.receiverId;
    
    if (!receiverId || senderId === receiverId) {
      return null;
    }

    try {
      // Get sender information
      const senderDoc = await admin.firestore()
        .collection('users')
        .doc(senderId)
        .get();
        
      const senderData = senderDoc.data();
      const senderName = senderData?.displayName || senderData?.name || 'Someone';
      
      // Get receiver's FCM tokens
      const tokensSnapshot = await admin.firestore()
        .collection('users')
        .doc(receiverId)
        .collection('fcmTokens')
        .where('isActive', '==', true)
        .get();
        
      const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
      
      if (tokens.length === 0) {
        console.log('No active tokens for user:', receiverId);
        return null;
      }
      
      // Check if conversation is muted
      const conversationDoc = await admin.firestore()
        .collection('conversations')
        .doc(conversationId)
        .get();
        
      const conversationData = conversationDoc.data();
      const mutedFor = conversationData?.mutedFor || [];
      
      if (mutedFor.includes(receiverId)) {
        console.log('Conversation is muted for user:', receiverId);
        return null;
      }
      
      // Send notification
      let notificationBody;
      switch (message.messageType) {
        case 'text':
          notificationBody = message.content;
          break;
        case 'image':
          notificationBody = '📷 Photo';
          break;
        case 'video':
          notificationBody = '🎥 Video';
          break;
        case 'audio':
          notificationBody = '🎵 Voice message';
          break;
        case 'document':
          notificationBody = '📄 Document';
          break;
        default:
          notificationBody = 'New message';
      }
      
      const fcmMessage = {
        tokens: tokens,
        notification: {
          title: senderName,
          body: notificationBody.length > 100 ? 
            notificationBody.substring(0, 100) + '...' : 
            notificationBody
        },
        data: {
          type: 'chat_message',
          conversationId: conversationId,
          senderId: senderId,
          senderName: senderName,
          messageId: messageId,
          messageType: message.messageType,
          timestamp: message.createdAt.seconds.toString()
        },
        android: {
          notification: {
            channelId: 'raabta_messages',
            priority: 'high'
          }
        }
      };
      
      const response = await admin.messaging().sendMulticast(fcmMessage);
      console.log('Notification sent:', response.successCount, 'successful,', response.failureCount, 'failed');
      
      // Clean up failed tokens
      if (response.failureCount > 0) {
        await cleanupFailedTokens(response.responses, tokens, receiverId);
      }
      
      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  });
```

## 🧹 Token Cleanup

```javascript
async function cleanupFailedTokens(responses, tokens, userId) {
  const batch = admin.firestore().batch();
  
  responses.forEach((response, index) => {
    if (!response.success) {
      const error = response.error;
      
      // Remove invalid tokens
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        const tokenRef = admin.firestore()
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(tokens[index]);
          
        batch.update(tokenRef, { isActive: false });
        console.log('Marking token as inactive:', tokens[index]);
      }
    }
  });
  
  await batch.commit();
}
```

## 📊 Notification Analytics

```javascript
// Track notification delivery and engagement
exports.trackNotificationDelivery = functions.https.onCall(async (data, context) => {
  const { messageId, userId, action } = data; // action: 'delivered', 'opened', 'dismissed'
  
  await admin.firestore()
    .collection('notificationAnalytics')
    .add({
      messageId,
      userId,
      action,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      platform: data.platform || 'unknown'
    });
    
  return { success: true };
});
```

## 🔐 Security Rules for FCM Tokens

```javascript
// Firestore security rules for FCM tokens
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // FCM tokens - users can only read/write their own tokens
    match /users/{userId}/fcmTokens/{tokenId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Notification analytics - users can only write their own analytics
    match /notificationAnalytics/{docId} {
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow read: if false; // Only server should read analytics
    }
  }
}
```

## 🧪 Testing Server-Side Notifications

### Test Function

```javascript
// Test notification endpoint
exports.testNotification = functions.https.onRequest(async (req, res) => {
  const { token, title, body } = req.body;
  
  if (!token || !title || !body) {
    res.status(400).json({ error: 'Missing required fields' });
    return;
  }
  
  const message = {
    token: token,
    notification: {
      title: title,
      body: body
    },
    data: {
      type: 'test',
      timestamp: Date.now().toString()
    }
  };
  
  try {
    const response = await admin.messaging().send(message);
    res.json({ success: true, messageId: response });
  } catch (error) {
    console.error('Test notification error:', error);
    res.status(500).json({ error: error.message });
  }
});
```

### cURL Test Command

```bash
curl -X POST https://your-project.cloudfunctions.net/testNotification \
  -H "Content-Type: application/json" \
  -d '{
    "token": "YOUR_FCM_TOKEN",
    "title": "Test Notification",
    "body": "This is a test message from the server"
  }'
```

## 📈 Best Practices

### 1. Rate Limiting

```javascript
const rateLimit = require('express-rate-limit');

const notificationLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many notification requests'
});

app.use('/api/notifications', notificationLimiter);
```

### 2. Batch Processing

```javascript
// Process notifications in batches to avoid rate limits
async function sendBatchNotifications(notifications) {
  const batchSize = 100;
  
  for (let i = 0; i < notifications.length; i += batchSize) {
    const batch = notifications.slice(i, i + batchSize);
    
    const promises = batch.map(notification => 
      sendChatNotification(notification.token, notification.senderName, 
        notification.content, notification.conversationId, 
        notification.senderId, notification.messageId)
    );
    
    await Promise.allSettled(promises);
    
    // Add delay between batches to respect rate limits
    if (i + batchSize < notifications.length) {
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }
}
```

### 3. Error Handling

```javascript
async function sendNotificationWithRetry(message, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const response = await admin.messaging().send(message);
      return response;
    } catch (error) {
      console.log(`Attempt ${attempt} failed:`, error.message);
      
      if (attempt === maxRetries) {
        throw error;
      }
      
      // Exponential backoff
      const delay = Math.pow(2, attempt) * 1000;
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}
```

## 🔍 Monitoring and Logging

```javascript
const { Logging } = require('@google-cloud/logging');
const logging = new Logging();

async function logNotificationEvent(event, data) {
  const log = logging.log('notification-events');
  
  const metadata = {
    resource: { type: 'cloud_function' },
    severity: 'INFO'
  };
  
  const entry = log.entry(metadata, {
    event,
    ...data,
    timestamp: new Date().toISOString()
  });
  
  await log.write(entry);
}

// Usage
await logNotificationEvent('notification_sent', {
  userId: receiverId,
  conversationId: conversationId,
  messageId: messageId,
  tokensCount: tokens.length,
  successCount: response.successCount,
  failureCount: response.failureCount
});
```

---

**Note**: Remember to replace placeholder values with your actual Firebase project configuration and implement proper error handling and security measures for production use.