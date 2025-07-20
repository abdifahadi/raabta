// Import Firebase scripts for service worker
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-messaging-compat.js');

// Initialize Firebase in service worker
// Note: You should replace these with your actual Firebase config
const firebaseConfig = {
  // This will be populated from your Firebase project
  // You can get this from Firebase Console > Project Settings > General > Your apps
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "your-app-id"
};

firebase.initializeApp(firebaseConfig);

// Initialize Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  // Extract notification data
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
    vibrate: [200, 100, 200]
  };

  // Show notification
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

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
    })
  );
});

// Handle notification close
self.addEventListener('notificationclose', (event) => {
  console.log('[firebase-messaging-sw.js] Notification closed:', event);
});

console.log('[firebase-messaging-sw.js] Service worker initialized');