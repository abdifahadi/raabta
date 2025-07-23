#!/bin/bash

# Deploy Firestore rules for Raabta app
echo "🔥 Deploying Firestore rules..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "🔑 Please login to Firebase:"
    firebase login
fi

# Deploy rules
echo "📤 Deploying rules..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo "✅ Firestore rules deployed successfully!"
    echo "📋 Rules include permissions for:"
    echo "   - Users collection"
    echo "   - Conversations and messages"
    echo "   - Groups and group messages"  
    echo "   - Calls collection (NEW)"
    echo "   - Notifications"
else
    echo "❌ Failed to deploy Firestore rules"
    exit 1
fi