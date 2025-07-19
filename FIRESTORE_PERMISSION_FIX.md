# Firestore Permission Fix Guide

## Problem
You're getting this error when trying to sign in:
```
Sign-in failed: Exception: Failed to save user from sign-in: Exception: Failed to check if user exists: [cloud_firestore/permission-denied] Missing or insufficient permissions.
```

## Root Cause
The Firebase Firestore security rules are either not properly configured or are too restrictive, preventing authenticated users from creating and reading their user documents.

## Solution

### Step 1: Deploy the New Security Rules

I've created proper Firestore security rules that will fix the permission issues. Run this command:

```bash
./deploy_firestore_rules.sh
```

If you don't have Firebase CLI installed or prefer manual deployment, follow Step 2.

### Step 2: Manual Firestore Rules Deployment

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Set the correct project**:
   ```bash
   firebase use abdifahadi-raabta
   ```

4. **Deploy the rules**:
   ```bash
   firebase deploy --only firestore:rules
   firebase deploy --only firestore:indexes
   ```

### Step 3: Verify in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/abdifahadi-raabta/firestore/rules)
2. Navigate to **Firestore Database** > **Rules**
3. Verify that the rules show as "Published"
4. The rules should look like this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - profiles and authentication data
    match /users/{userId} {
      // Anyone authenticated can read user profiles
      allow read: if request.auth != null;
      
      // Only the user themselves can write to their profile
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    // ... other rules
  }
}
```

### Step 4: Test the Fix

1. Clear your browser cache and cookies for localhost:57577
2. Try signing in again with Google
3. The sign-in process should now work without permission errors

## Alternative Quick Fix (Temporary)

If you need a quick temporary fix for testing, you can temporarily set very permissive rules (NOT recommended for production):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**⚠️ WARNING**: This allows all authenticated users to read/write all documents. Only use this for testing and replace with proper rules immediately.

## What the New Rules Do

1. **Users Collection**: 
   - ✅ Authenticated users can read any user profile (needed for chat features)
   - ✅ Users can only create/update/delete their own profile
   - ✅ Fixes the permission error during sign-in

2. **Conversations Collection**:
   - ✅ Only conversation participants can read conversations
   - ✅ Users can create conversations with themselves and one other user
   - ✅ Prevents unauthorized access to private conversations

3. **Messages Subcollection**:
   - ✅ Only conversation participants can read messages
   - ✅ Only message sender can create/update/delete their messages
   - ✅ Maintains message privacy and security

## Troubleshooting

If you still get permission errors after deployment:

1. **Wait 1-2 minutes** for rules to propagate
2. **Clear browser cache** completely
3. **Check Firebase Console** to ensure rules are published
4. **Verify project ID** matches in firebase.json and your app
5. **Check network connection** to Firebase

## Files Created/Modified

- `firestore.rules` - New security rules
- `firebase.json` - Firebase configuration
- `firestore.indexes.json` - Database indexes
- `deploy_firestore_rules.sh` - Deployment script

## Next Steps

After fixing the permission issue:

1. Test all app functionality
2. Monitor Firebase Console for any new permission errors
3. Review and adjust rules as needed for new features

---

**Need Help?** Check the Firebase Console logs at: https://console.firebase.google.com/project/abdifahadi-raabta/firestore