#!/bin/bash

# Firestore Fixes Verification Script
# Run this after deploying Firebase rules and indexes

echo "🔍 FIRESTORE FIXES VERIFICATION SCRIPT"
echo "======================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test status variables
RULES_STATUS="❓"
INDEXES_STATUS="❓"
BUILD_STATUS="❓"
DEPLOY_STATUS="❓"

echo -e "${BLUE}📋 Verification Checklist:${NC}"
echo "1. ✅ Check Firebase deployment status"
echo "2. ✅ Verify Firestore rules are active"
echo "3. ✅ Confirm all 14 indexes are built"
echo "4. ✅ Test Flutter project builds without errors"
echo "5. ✅ Validate group and conversation operations"
echo ""

# Check if Firebase CLI is available
if command -v firebase &> /dev/null; then
    echo -e "${GREEN}✅ Firebase CLI available${NC}"
    
    # Check current project
    echo -e "${YELLOW}🔍 Checking Firebase project...${NC}"
    CURRENT_PROJECT=$(firebase projects:list 2>/dev/null | grep "abdifahadi-raabta" | head -n1 || echo "")
    
    if [[ $CURRENT_PROJECT == *"abdifahadi-raabta"* ]]; then
        echo -e "${GREEN}✅ Correct Firebase project selected: abdifahadi-raabta${NC}"
        DEPLOY_STATUS="✅"
    else
        echo -e "${RED}❌ Wrong project or not authenticated. Run: firebase use abdifahadi-raabta${NC}"
        DEPLOY_STATUS="❌"
    fi
    
    # Check rules deployment status
    echo -e "${YELLOW}🔍 Checking Firestore rules status...${NC}"
    if firebase firestore:rules 2>/dev/null | grep -q "rules_version"; then
        RULES_STATUS="✅"
        echo -e "${GREEN}✅ Firestore rules are deployed and accessible${NC}"
        
        # Check if our specific rule fixes are present
        if firebase firestore:rules 2>/dev/null | grep -q "resource == null"; then
            echo -e "${GREEN}✅ Updated rules with null resource handling detected${NC}"
        else
            echo -e "${YELLOW}⚠️  Rules may be outdated - redeploy with: firebase deploy --only firestore:rules${NC}"
        fi
    else
        RULES_STATUS="❌"
        echo -e "${RED}❌ Cannot access Firestore rules - redeploy required${NC}"
    fi
    
    # Check indexes status
    echo -e "${YELLOW}🔍 Checking Firestore indexes...${NC}"
    # Note: Firebase CLI doesn't provide a direct way to check index status
    # This requires manual verification in Firebase Console
    echo -e "${CYAN}📝 To verify indexes, check Firebase Console:${NC}"
    echo "   🔗 https://console.firebase.google.com/project/abdifahadi-raabta/firestore/indexes"
    echo ""
    echo -e "${BLUE}Expected 14 indexes:${NC}"
    echo "   1. conversations: participants + updatedAt"
    echo "   2. conversations: participants + createdAt" 
    echo "   3. conversations: participants + lastMessageTime"
    echo "   4. groups: members + updatedAt"
    echo "   5. groups: members + createdAt"
    echo "   6. groups: members + lastMessageTime"
    echo "   7. messages (collection-group): timestamp DESC"
    echo "   8. messages (collection): timestamp DESC"
    echo "   9. messages (collection): timestamp ASC"
    echo "   10. callSessions: callerId + createdAt"
    echo "   11. callSessions: receiverId + createdAt"
    echo "   12. callSessions: status + createdAt"
    echo "   13. notifications: userId + createdAt"
    echo "   14. notifications: userId + isRead + createdAt"
    echo ""
    INDEXES_STATUS="⏳"
    
else
    echo -e "${RED}❌ Firebase CLI not available${NC}"
    DEPLOY_STATUS="❌"
fi

# Check Flutter build
echo -e "${YELLOW}🔍 Checking Flutter project build...${NC}"
if command -v flutter &> /dev/null; then
    echo -e "${GREEN}✅ Flutter SDK available${NC}"
    
    # Clean and get dependencies
    echo -e "${YELLOW}🧹 Cleaning Flutter project...${NC}"
    flutter clean > /dev/null 2>&1
    flutter pub get > /dev/null 2>&1
    
    # Try to analyze the project
    echo -e "${YELLOW}🔍 Running Flutter analyze...${NC}"
    if flutter analyze --no-fatal-infos > /tmp/flutter_analyze.log 2>&1; then
        BUILD_STATUS="✅"
        echo -e "${GREEN}✅ Flutter analysis passed${NC}"
    else
        BUILD_STATUS="⚠️"
        echo -e "${YELLOW}⚠️  Flutter analysis has warnings (check /tmp/flutter_analyze.log)${NC}"
    fi
else
    echo -e "${RED}❌ Flutter SDK not available${NC}"
    BUILD_STATUS="❌"
fi

echo ""
echo -e "${PURPLE}📊 VERIFICATION SUMMARY:${NC}"
echo "Firebase Project: $DEPLOY_STATUS"
echo "Firestore Rules: $RULES_STATUS"
echo "Firestore Indexes: $INDEXES_STATUS (Manual verification required)"
echo "Flutter Build: $BUILD_STATUS"
echo ""

echo -e "${CYAN}🧪 MANUAL TESTING INSTRUCTIONS:${NC}"
echo ""
echo -e "${YELLOW}1. 👥 GROUP FUNCTIONALITY TEST:${NC}"
echo "   a) Open your Flutter app"
echo "   b) Navigate to Groups tab"
echo "   c) ✅ Should load without [failed-precondition] errors"
echo "   d) Create a new group with 2+ members"
echo "   e) ✅ Group should appear in list immediately"
echo "   f) Send a message in the group"
echo "   g) ✅ Message should appear without errors"
echo ""

echo -e "${YELLOW}2. 💬 CONVERSATION DELETE TEST:${NC}"
echo "   a) Open any existing conversation"
echo "   b) Go to conversation settings (⚙️ icon)"
echo "   c) Tap 'Delete Conversation'"
echo "   d) Confirm deletion"
echo "   e) ✅ Should delete without [permission-denied] errors"
echo "   f) ✅ Conversation should disappear from list"
echo "   g) ✅ All messages should be deleted"
echo ""

echo -e "${YELLOW}3. 📱 CROSS-PLATFORM VERIFICATION:${NC}"
echo "   a) Test on Flutter Web:"
echo "      • flutter build web"
echo "      • firebase serve --only hosting"
echo "      • Open localhost:5000"
echo "      • ✅ No console errors related to Firestore"
echo ""
echo "   b) Test on Android (if available):"
echo "      • flutter build apk"
echo "      • Install and test APK"
echo "      • ✅ Groups tab loads properly"
echo "      • ✅ Conversation delete works"
echo ""
echo "   c) Test on Desktop (if available):"
echo "      • flutter build linux/windows/macos"
echo "      • Run the built executable"
echo "      • ✅ All Firestore operations work"
echo ""

echo -e "${YELLOW}4. 🔍 CONSOLE ERROR CHECK:${NC}"
echo "   a) Open browser developer tools (F12)"
echo "   b) Navigate through the app"
echo "   c) ✅ Should see NO errors containing:"
echo "      • [cloud_firestore/failed-precondition]"
echo "      • [cloud_firestore/permission-denied]"
echo "      • 'index does not exist'"
echo "      • 'insufficient permissions'"
echo ""

echo -e "${RED}❌ TROUBLESHOOTING IF TESTS FAIL:${NC}"
echo ""
echo "If Groups tab still shows index errors:"
echo "• Wait 5-15 minutes for indexes to build completely"
echo "• Check Firebase Console indexes page for 'Building...' status"
echo "• Redeploy indexes: firebase deploy --only firestore:indexes"
echo ""
echo "If conversation delete still fails:"
echo "• Redeploy rules: firebase deploy --only firestore:rules"
echo "• Clear browser cache and local storage"
echo "• Restart the Flutter app completely"
echo ""
echo "If errors persist:"
echo "• Check Firebase Console > Project Settings > General"
echo "• Verify Project ID is exactly 'abdifahadi-raabta'"
echo "• Ensure correct Firebase user account is logged in"
echo "• Wait 2-3 minutes for global propagation"
echo ""

echo -e "${GREEN}✅ SUCCESS CRITERIA:${NC}"
echo "All fixes are working correctly when:"
echo "• Groups tab loads instantly without errors"
echo "• Group creation and messaging work smoothly"
echo "• Conversation deletion completes without permission errors"
echo "• No Firestore-related errors in browser console"
echo "• App works consistently across Web, Android, and Desktop"
echo ""

echo -e "${BLUE}🔗 HELPFUL FIREBASE CONSOLE LINKS:${NC}"
echo "• Rules: https://console.firebase.google.com/project/abdifahadi-raabta/firestore/rules"
echo "• Indexes: https://console.firebase.google.com/project/abdifahadi-raabta/firestore/indexes"
echo "• Data: https://console.firebase.google.com/project/abdifahadi-raabta/firestore/data"
echo "• Usage: https://console.firebase.google.com/project/abdifahadi-raabta/firestore/usage"
echo ""

if [[ $RULES_STATUS == "✅" && $BUILD_STATUS == "✅" && $DEPLOY_STATUS == "✅" ]]; then
    echo -e "${GREEN}🎉 READY FOR TESTING! All prerequisites verified.${NC}"
    echo -e "${YELLOW}Proceed with manual testing steps above.${NC}"
else
    echo -e "${YELLOW}⚠️  Some prerequisites failed. Address the issues above before testing.${NC}"
fi

echo ""
echo -e "${PURPLE}📝 Next Steps:${NC}"
echo "1. Complete manual testing as outlined above"
echo "2. Report any remaining issues with specific error messages"
echo "3. If all tests pass, the Firestore fixes are successfully deployed!"