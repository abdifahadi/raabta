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
NC='\033[0m'

# Test status variables
RULES_STATUS="❓"
INDEXES_STATUS="❓"
BUILD_STATUS="❓"

echo -e "${BLUE}📋 Verification Checklist:${NC}"
echo "1. Check Firebase deployment status"
echo "2. Verify Flutter project builds without errors"
echo "3. Test Firestore operations"
echo ""

# Check if Firebase CLI is available
if command -v firebase &> /dev/null; then
    echo -e "${GREEN}✅ Firebase CLI available${NC}"
    
    # Check current project
    echo -e "${YELLOW}🔍 Checking Firebase project...${NC}"
    CURRENT_PROJECT=$(firebase projects:list 2>/dev/null | grep "abdifahadi-raabta" | head -n1 || echo "")
    
    if [[ $CURRENT_PROJECT == *"abdifahadi-raabta"* ]]; then
        echo -e "${GREEN}✅ Correct Firebase project selected: abdifahadi-raabta${NC}"
    else
        echo -e "${RED}❌ Wrong project or not authenticated. Run: firebase use abdifahadi-raabta${NC}"
    fi
    
    # Check rules deployment status
    echo -e "${YELLOW}🔍 Checking Firestore rules status...${NC}"
    if firebase firestore:rules 2>/dev/null | grep -q "rules_version"; then
        RULES_STATUS="✅"
        echo -e "${GREEN}✅ Firestore rules are accessible${NC}"
    else
        RULES_STATUS="❌"
        echo -e "${RED}❌ Cannot access Firestore rules${NC}"
    fi
    
else
    echo -e "${RED}❌ Firebase CLI not available${NC}"
    echo "Install with: npm install -g firebase-tools"
fi

echo ""

# Check Flutter build
echo -e "${YELLOW}🔍 Checking Flutter build status...${NC}"

# Check if Flutter is available in standard locations
FLUTTER_PATHS=(
    "/workspace/flutter/bin/flutter"
    "flutter"
    "/usr/local/bin/flutter"
    "/opt/flutter/bin/flutter"
)

FLUTTER_CMD=""
for path in "${FLUTTER_PATHS[@]}"; do
    if command -v "$path" &> /dev/null; then
        FLUTTER_CMD="$path"
        break
    fi
done

if [[ -n "$FLUTTER_CMD" ]]; then
    echo -e "${GREEN}✅ Flutter found at: $FLUTTER_CMD${NC}"
    
    # Check if this is a Flutter project
    if [[ -f "pubspec.yaml" ]]; then
        echo -e "${GREEN}✅ Flutter project detected${NC}"
        
        # Run flutter analyze
        echo -e "${YELLOW}🔍 Running Flutter analyze...${NC}"
        if $FLUTTER_CMD analyze --no-pub 2>/dev/null | grep -q "No issues found"; then
            BUILD_STATUS="✅"
            echo -e "${GREEN}✅ Flutter analyze passed - no issues found${NC}"
        else
            BUILD_STATUS="⚠️"
            echo -e "${YELLOW}⚠️ Flutter analyze found some issues (check manually)${NC}"
        fi
        
    else
        echo -e "${RED}❌ pubspec.yaml not found - not a Flutter project${NC}"
    fi
else
    echo -e "${RED}❌ Flutter not found in PATH${NC}"
    BUILD_STATUS="❌"
fi

echo ""

# Check critical files
echo -e "${YELLOW}🔍 Checking critical Firestore files...${NC}"

CRITICAL_FILES=(
    "firestore.rules"
    "firestore.indexes.json" 
    "firebase.json"
    "lib/core/config/firebase_options.dart"
)

ALL_FILES_PRESENT=true

for file in "${CRITICAL_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✅ $file present${NC}"
    else
        echo -e "${RED}❌ $file missing${NC}"
        ALL_FILES_PRESENT=false
    fi
done

echo ""

# Summary
echo -e "${PURPLE}📊 VERIFICATION SUMMARY:${NC}"
echo -e "Firebase Rules: $RULES_STATUS"
echo -e "Firestore Indexes: $INDEXES_STATUS" 
echo -e "Flutter Build: $BUILD_STATUS"
echo -e "Critical Files: $([ "$ALL_FILES_PRESENT" = true ] && echo "✅" || echo "❌")"

echo ""

# Manual verification steps
echo -e "${BLUE}📱 MANUAL VERIFICATION STEPS:${NC}"
echo ""
echo "After successful Firebase deployment, test these scenarios:"
echo ""
echo -e "${YELLOW}1. Group Loading Test:${NC}"
echo "   • Open the Groups tab in your app"
echo "   • Should load without 'The query requires an index' error"
echo "   • Create a new group - should appear immediately"
echo ""
echo -e "${YELLOW}2. Conversation Delete Test:${NC}"
echo "   • Try to delete a conversation"
echo "   • Should work without 'permission-denied' error"
echo ""
echo -e "${YELLOW}3. Real-time Updates Test:${NC}"
echo "   • Send messages - should appear instantly"
echo "   • Check cross-device synchronization"
echo ""

# Firebase Console URLs
echo -e "${PURPLE}🌐 Firebase Console URLs:${NC}"
echo "Rules: https://console.firebase.google.com/project/abdifahadi-raabta/firestore/rules"
echo "Indexes: https://console.firebase.google.com/project/abdifahadi-raabta/firestore/indexes"
echo "Data: https://console.firebase.google.com/project/abdifahadi-raabta/firestore/data"
echo ""

# Deployment commands reminder
echo -e "${RED}⚠️  DEPLOYMENT COMMANDS (if not done yet):${NC}"
echo "firebase login"
echo "firebase use abdifahadi-raabta"  
echo "firebase deploy --only firestore:rules"
echo "firebase deploy --only firestore:indexes"
echo ""

# Build and test commands
echo -e "${BLUE}🚀 BUILD AND TEST COMMANDS:${NC}"
echo "# Web build and test:"
echo "flutter build web"
echo "firebase serve --only hosting"
echo ""
echo "# Android build:"
echo "flutter build apk --release"
echo ""
echo "# Desktop build (Linux):"
echo "flutter build linux"
echo ""

# Expected results
echo -e "${GREEN}🎯 EXPECTED RESULTS AFTER DEPLOYMENT:${NC}"
echo "✅ Groups tab loads instantly without index errors"
echo "✅ Conversations can be deleted without permission errors"
echo "✅ No Firestore warnings in browser console"
echo "✅ Real-time updates work across all features"
echo "✅ All CRUD operations function correctly"
echo ""

echo -e "${YELLOW}📝 NOTE: Index creation in Firebase Console may take 5-10 minutes${NC}"
echo -e "${YELLOW}📝 Rules take effect immediately after deployment${NC}"
echo ""

echo -e "${GREEN}✨ Verification script completed!${NC}"
echo -e "${BLUE}Check the results above and test manually in your app.${NC}"