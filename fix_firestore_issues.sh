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
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Issues Fixed:${NC}"
echo "1. ✅ COMPOSITE INDEX ERROR - Groups Tab loading with members + updatedAt/createdAt"
echo "2. ✅ CONVERSATION DELETE PERMISSION ERROR - Fixed resource == null handling"  
echo "3. ✅ Added comprehensive indexes for all query patterns (14 total indexes)"
echo "4. ✅ Fixed batch delete operations for conversations and messages"
echo ""

echo -e "${CYAN}🔧 Changes Made:${NC}"
echo "• Updated firestore.rules with proper null resource handling"
echo "• Enhanced firestore.indexes.json with all 14 required composite indexes"
echo "• Fixed conversation delete permissions for batch operations"
echo "• Added indexes for groups, conversations, messages, calls, and notifications"
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
echo -e "${PURPLE}🚀 CRITICAL DEPLOYMENT STEPS:${NC}"
echo "Run these commands in order:"
echo ""

echo -e "${YELLOW}Step 1: Authenticate with Firebase${NC}"
echo "firebase login"
echo ""

echo -e "${YELLOW}Step 2: Set the correct project${NC}"
echo "firebase use abdifahadi-raabta"
echo ""

echo -e "${YELLOW}Step 3: Deploy Firestore rules (CRITICAL - Fixes Permission Errors)${NC}"
echo "firebase deploy --only firestore:rules"
echo ""

echo -e "${YELLOW}Step 4: Deploy Firestore indexes (CRITICAL - Fixes Composite Index Errors)${NC}"
echo "firebase deploy --only firestore:indexes"
echo ""

echo -e "${BLUE}📝 Index Summary (14 total):${NC}"
echo "• Conversations: participants + updatedAt/createdAt/lastMessageTime"
echo "• Groups: members + updatedAt/createdAt/lastMessageTime"  
echo "• Messages: timestamp (both collection and collection-group)"
echo "• Call Sessions: callerId/receiverId/status + createdAt"
echo "• Notifications: userId + createdAt, userId + isRead + createdAt"
echo ""

echo -e "${GREEN}✅ Expected Results After Deployment:${NC}"
echo "• No more [cloud_firestore/failed-precondition] errors on Groups tab"
echo "• No more [cloud_firestore/permission-denied] on conversation delete"
echo "• Faster query performance across all collections"
echo "• Proper batch delete operations for conversations and messages"
echo ""

echo -e "${CYAN}🧪 Testing Instructions:${NC}"
echo "After deployment, test these scenarios:"
echo ""
echo "1. 👥 GROUP FUNCTIONALITY:"
echo "   • Load Groups tab - should load without errors"
echo "   • Create a new group with multiple members"
echo "   • Verify group appears in the list immediately"
echo "   • Send messages in the group"
echo ""
echo "2. 💬 CONVERSATION FUNCTIONALITY:"
echo "   • Open any conversation"
echo "   • Go to conversation settings"
echo "   • Try 'Delete Conversation' - should work without permission errors"
echo "   • Verify conversation and all messages are deleted"
echo ""
echo "3. 📱 CROSS-PLATFORM TESTING:"
echo "   • Test on Flutter Web"
echo "   • Test on Android"
echo "   • Test on Desktop"
echo "   • All should work without runtime errors"
echo ""

echo -e "${RED}⚠️  IMPORTANT NOTES:${NC}"
echo "• Index deployment may take 5-15 minutes to complete"
echo "• Wait for 'Index creation completed' message before testing"
echo "• If you see 'Building index...' status, wait for completion"
echo "• Test each functionality after deployment to ensure no regressions"
echo ""

echo -e "${PURPLE}🔍 Verification Commands:${NC}"
echo "After deployment, run: ./verify_firestore_fixes.sh"
echo ""

echo "✨ Script completed! Run the deployment commands above to fix all Firestore issues."