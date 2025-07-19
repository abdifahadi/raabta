#!/bin/bash

# Deploy Firestore Rules Script
# This script deploys the Firestore security rules to fix permission issues

echo "🔥 Deploying Firestore Rules to Fix Permission Issues..."
echo "========================================================="

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Installing now..."
    npm install -g firebase-tools
fi

# Login to Firebase (if not already logged in)
echo "🔐 Checking Firebase authentication..."
firebase login --no-localhost

# Select the correct Firebase project
echo "📋 Setting Firebase project..."
firebase use abdifahadi-raabta

# Deploy Firestore rules only
echo "🚀 Deploying Firestore security rules..."
firebase deploy --only firestore:rules

# Deploy Firestore indexes
echo "📊 Deploying Firestore indexes..."
firebase deploy --only firestore:indexes

echo "✅ Firestore rules and indexes deployed successfully!"
echo ""
echo "🔧 Additional steps to ensure permissions work:"
echo "1. Check your Firebase Console > Firestore > Rules"
echo "2. Verify that the rules show as 'Published'"
echo "3. Test the sign-in process again"
echo ""
echo "🌐 Firebase Console: https://console.firebase.google.com/project/abdifahadi-raabta/firestore"

# Optional: Test the rules
echo "🧪 Would you like to test the Firestore rules? (y/n)"
read -r test_rules

if [[ $test_rules == "y" || $test_rules == "Y" ]]; then
    echo "🔍 Opening Firebase Console Rules Playground..."
    echo "Navigate to: https://console.firebase.google.com/project/abdifahadi-raabta/firestore/rules"
    echo "Test with:"
    echo "  - Path: /users/{userId}"
    echo "  - Method: create/read"
    echo "  - Auth: Simulate signed-in user with UID"
fi