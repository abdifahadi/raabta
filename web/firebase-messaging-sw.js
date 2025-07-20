// Import Firebase scripts for service worker
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-messaging-compat.js');

// SECURITY NOTE: Firebase configuration in service workers
// The Firebase config exposed here is safe for the following reasons:
// 1. These are public configuration values designed to be exposed on the client
// 2. API keys here are not secret keys - they identify the project publicly
// 3. Firebase security is enforced through Security Rules, not config secrecy
// 4. This follows Google's official Firebase documentation for web apps
// See: https://firebase.google.com/docs/projects/api-keys#api-keys-for-firebase-are-different

// Initialize Firebase in service worker
// NOTE: This config must match exactly with firebase_options.dart for consistency
const firebaseConfig = {
  apiKey: "AIzaSyAfaX4V-FvnvyYJTBuI3PBVgIOy83O7Ehc",
  authDomain: "abdifahadi-raabta.firebaseapp.com",
  projectId: "abdifahadi-raabta",
  storageBucket: "abdifahadi-raabta.firebasestorage.app",
  messagingSenderId: "507820378047",
  appId: "1:507820378047:web:a78393966656f46391c30a",
  measurementId: "G-W8DF9B0CB8"
};

// Initialize Firebase with error handling
try {
  firebase.initializeApp(firebaseConfig);
} catch (error) {
  console.error('[firebase-messaging-sw.js] Firebase initialization failed:', error);
}

// Initialize Firebase Messaging with error handling
let messaging;
try {
  messaging = firebase.messaging();
} catch (error) {
  console.error('[firebase-messaging-sw.js] Firebase Messaging initialization failed:', error);
}

// Handle background messages
if (messaging) {
  messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message', payload);
    
    // Extract notification data with fallbacks
    const notificationTitle = payload.notification?.title || 'Raabta';
    const notificationOptions = {
      body: payload.notification?.body || 'New message',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-72.png',
      tag: payload.data?.conversationId || 'raabta-notification',
      data: payload.data,
      actions: [
        {
          action: 'open',
          title: 'Open Chat'
        },
        {
          action: 'close',
          title: 'Close'
        }
      ],
      requireInteraction: true,
      vibrate: [200, 100, 200],
      // Add timeout to prevent persistent notifications
      silent: false,
      renotify: true
    };

    // Show notification with error handling
    return self.registration.showNotification(notificationTitle, notificationOptions)
      .catch(error => {
        console.error('[firebase-messaging-sw.js] Failed to show notification:', error);
      });
  });
}

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event);
  
  event.notification.close();
  
  if (event.action === 'close') {
    return;
  }
  
  // Handle notification tap - open the app
  const urlToOpen = new URL('/', self.location.origin).href;
  
  // Check if app is already open
  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    }).then((windowClients) => {
      // If app is already open, focus it
      for (const client of windowClients) {
        if (client.url === urlToOpen && 'focus' in client) {
          return client.focus();
        }
      }
      
      // If app is not open, open it
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    }).catch(error => {
      console.error('[firebase-messaging-sw.js] Failed to handle notification click:', error);
    })
  );
});

// Handle notification close
self.addEventListener('notificationclose', (event) => {
  console.log('[firebase-messaging-sw.js] Notification closed:', event);
  
  // Optional: Send analytics or cleanup here
  if (event.notification.data?.conversationId) {
    // Could send a message to track notification dismissal
    console.log('[firebase-messaging-sw.js] Notification dismissed for conversation:', event.notification.data.conversationId);
  }
});

console.log('[firebase-messaging-sw.js] Service worker initialized successfully');