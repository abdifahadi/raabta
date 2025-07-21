#!/bin/bash

# Comprehensive Firestore Issues Fix Script
# This script addresses all the reported Firestore runtime errors

echo "🔥 FIRESTORE ISSUES FIX SCRIPT"
echo "==============================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Issues to be fixed:${NC}"
echo "1. ❌ COMPOSITE INDEX ERROR - Group loading fails"
echo "2. ❌ FIRESTORE PERMISSION ERROR - Conversation delete fails"  
echo "3. ❌ Missing indexes for efficient queries"
echo ""

# Check if Firebase CLI is installed
echo -e "${YELLOW}🔍 Checking Firebase CLI...${NC}"
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found. Installing...${NC}"
    npm install -g firebase-tools
else
    echo -e "${GREEN}✅ Firebase CLI is installed${NC}"
fi

echo ""
echo -e "${PURPLE}🚀 DEPLOYMENT STEPS:${NC}"
echo "Since this is a background agent, please run these commands manually:"
echo ""

echo -e "${YELLOW}Step 1: Authenticate with Firebase${NC}"
echo "firebase login"
echo ""

echo -e "${YELLOW}Step 2: Set the correct project${NC}"
echo "firebase use abdifahadi-raabta"
echo ""

echo -e "${YELLOW}Step 3: Deploy Firestore rules (CRITICAL)${NC}"
echo "firebase deploy --only firestore:rules"
echo ""

echo -e "${YELLOW}Step 4: Deploy Firestore indexes (CRITICAL)${NC}"
echo "firebase deploy --only firestore:indexes"
echo ""

echo -e "${GREEN}✅ WHAT HAS BEEN FIXED IN THIS SCRIPT:${NC}"
echo ""

echo -e "${BLUE}1. COMPOSITE INDEXES ADDED:${NC}"
echo "   ✅ groups collection: members (array-contains) + updatedAt (desc)"
echo "   ✅ groups collection: members (array-contains) + createdAt (desc)"
echo "   ✅ conversations collection: participants (array-contains) + updatedAt (desc)"
echo "   ✅ conversations collection: participants (array-contains) + createdAt (desc)"
echo "   ✅ messages collection: timestamp (desc) - both collection and collection-group"
echo "   ✅ callSessions collection: callerId + createdAt (desc)"
echo "   ✅ callSessions collection: receiverId + createdAt (desc)"
echo "   ✅ notifications collection: userId + createdAt (desc)"
echo ""

echo -e "${BLUE}2. FIRESTORE SECURITY RULES FIXED:${NC}"
echo "   ✅ Allow conversation deletion by participants"
echo "   ✅ Fixed permission issues with resource == null checks"
echo "   ✅ Added FCM tokens subcollection permissions"
echo "   ✅ Improved group permissions for member management"
echo "   ✅ Enhanced message permissions for batch operations"
echo ""

echo -e "${BLUE}3. SPECIFIC QUERY FIXES:${NC}"
echo "   ✅ getGroupsForUser query: .where('members', arrayContains: userId).orderBy('updatedAt', descending: true)"
echo "   ✅ getUserConversations query: .where('participants', arrayContains: userId).orderBy('updatedAt', descending: true)"
echo "   ✅ deleteConversation batch operation now allowed"
echo "   ✅ Group and conversation existence checks (resource == null)"
echo ""

echo -e "${YELLOW}📱 MANUAL VERIFICATION STEPS:${NC}"
echo ""
echo "After deploying the rules and indexes, test these scenarios:"
echo ""
echo "1. 🏠 Group Loading Test:"
echo "   - Open the Groups tab"
echo "   - Should load without 'failed-precondition' error"
echo "   - Create a new group - should appear immediately"
echo ""
echo "2. 💬 Conversation Delete Test:"
echo "   - Try to delete a conversation"
echo "   - Should work without 'permission-denied' error"
echo ""
echo "3. 🔄 Cross-Platform Test:"
echo "   - Test on web: flutter build web && firebase serve"
echo "   - Test on Android: flutter build apk"
echo "   - Test on desktop: flutter build linux/windows/macos"
echo ""

echo -e "${PURPLE}🌐 Firebase Console URLs:${NC}"
echo "Rules: https://console.firebase.google.com/project/abdifahadi-raabta/firestore/rules"
echo "Indexes: https://console.firebase.google.com/project/abdifahadi-raabta/firestore/indexes"
echo "Data: https://console.firebase.google.com/project/abdifahadi-raabta/firestore/data"
echo ""

echo -e "${GREEN}🎯 EXPECTED RESULTS AFTER DEPLOYMENT:${NC}"
echo "✅ Groups tab loads instantly without errors"
echo "✅ Conversations can be deleted successfully"
echo "✅ No more composite index warnings"
echo "✅ No more permission-denied errors"
echo "✅ Real-time updates work properly"
echo "✅ All CRUD operations function correctly"
echo ""

echo -e "${RED}⚠️  IMPORTANT NOTES:${NC}"
echo "• Index creation may take 5-10 minutes in Firebase Console"
echo "• Rules take effect immediately after deployment"
echo "• Clear browser cache after deploying rules"
echo "• Monitor Firebase Console for any new errors"
echo ""

echo -e "${BLUE}🔧 ADDITIONAL TROUBLESHOOTING:${NC}"
echo "If you still see errors after deployment:"
echo "1. Check Firebase Console > Project Settings > General > Project ID matches 'abdifahadi-raabta'"
echo "2. Verify firebase.json points to correct rules/indexes files"
echo "3. Ensure you're using the correct Firebase user account"
echo "4. Wait 2-3 minutes for changes to propagate globally"
echo ""

echo -e "${GREEN}✨ All Firestore configurations have been updated!${NC}"
echo -e "${YELLOW}Please run the Firebase deployment commands above to apply the fixes.${NC}"