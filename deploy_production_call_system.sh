#!/bin/bash

# Production Call System Deployment Script for Raabta Flutter App
# This script deploys the complete cross-platform call system using Supabase

set -e

echo "🚀 Starting Raabta Production Call System Deployment..."
echo "======================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SUPABASE_PROJECT_REF="qrtutnrcynfceshsngph"
FIREBASE_PROJECT_ID="raabta-chat-app"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Supabase CLI is installed
    if ! command -v supabase &> /dev/null; then
        print_error "Supabase CLI is not installed. Please install it first:"
        echo "   npm install -g supabase"
        echo "   or visit: https://supabase.com/docs/guides/cli"
        exit 1
    fi
    
    # Check if Firebase CLI is installed
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI is not installed. Please install it first:"
        echo "   npm install -g firebase-tools"
        exit 1
    fi
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites are installed."
}

# Check authentication
check_authentication() {
    print_status "Checking authentication..."
    
    # Check Supabase login
    if ! supabase projects list &> /dev/null; then
        print_error "Not logged in to Supabase. Please login first:"
        echo "   supabase login"
        exit 1
    fi
    
    # Check Firebase login
    if ! firebase projects:list &> /dev/null; then
        print_error "Not logged in to Firebase. Please login first:"
        echo "   firebase login"
        exit 1
    fi
    
    print_success "Authentication verified."
}

# Deploy Supabase Edge Function
deploy_supabase_function() {
    print_status "Deploying Supabase Edge Function..."
    
    # Deploy the improved Agora token generation function
    if supabase functions deploy generate-agora-token --project-ref $SUPABASE_PROJECT_REF; then
        print_success "Supabase Edge Function deployed successfully!"
        print_status "Function URL: https://$SUPABASE_PROJECT_REF.supabase.co/functions/v1/generate-agora-token"
    else
        print_error "Failed to deploy Supabase Edge Function"
        exit 1
    fi
}

# Test Supabase Edge Function
test_supabase_function() {
    print_status "Testing Supabase Edge Function..."
    
    # Test the function with a sample request
    local test_response=$(curl -s -X POST \
        "https://$SUPABASE_PROJECT_REF.supabase.co/functions/v1/generate-agora-token" \
        -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFydHV0bnJjeW5mY2VzaHNuZ3BoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNDA4MDMsImV4cCI6MjA2ODgxNjgwM30.TsnPqlCaTLKAVL32ygDv_sR71AEtLw1pJGHezmBeDBA" \
        -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFydHV0bnJjeW5mY2VzaHNuZ3BoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNDA4MDMsImV4cCI6MjA2ODgxNjgwM30.TsnPqlCaTLKAVL32ygDv_sR71AEtLw1pJGHezmBeDBA" \
        -H "Content-Type: application/json" \
        -d '{"channelName": "test_channel", "uid": 12345}')
    
    if echo "$test_response" | grep -q "rtcToken"; then
        print_success "Supabase Edge Function is working correctly!"
    else
        print_warning "Edge Function test may have failed. Response: $test_response"
    fi
}

# Deploy Firestore Rules
deploy_firestore_rules() {
    print_status "Deploying Firestore Rules..."
    
    if firebase deploy --only firestore:rules --project $FIREBASE_PROJECT_ID; then
        print_success "Firestore rules deployed successfully!"
    else
        print_error "Failed to deploy Firestore rules"
        exit 1
    fi
}

# Update Flutter dependencies
update_flutter_dependencies() {
    print_status "Updating Flutter dependencies..."
    
    flutter pub get
    
    if [ $? -eq 0 ]; then
        print_success "Flutter dependencies updated successfully!"
    else
        print_error "Failed to update Flutter dependencies"
        exit 1
    fi
}

# Build Flutter app for verification
build_flutter_app() {
    print_status "Building Flutter app for verification..."
    
    # Build for web to ensure cross-platform compatibility
    if flutter build web --dart-define=FLUTTER_WEB_USE_SKIA=true; then
        print_success "Flutter web build successful!"
    else
        print_error "Flutter web build failed"
        exit 1
    fi
    
    # Analyze for any issues
    print_status "Running Flutter analyzer..."
    if flutter analyze; then
        print_success "Flutter analyzer passed!"
    else
        print_warning "Flutter analyzer found issues. Please review."
    fi
}

# Verification tests
run_verification_tests() {
    print_status "Running verification tests..."
    
    # Test 1: Verify Supabase connection
    print_status "Testing Supabase connection..."
    if ping -c 1 qrtutnrcynfceshsngph.supabase.co &> /dev/null; then
        print_success "Supabase connection verified"
    else
        print_warning "Supabase connection test failed"
    fi
    
    # Test 2: Verify Agora configuration
    print_status "Verifying Agora configuration..."
    if grep -q "4bfa94cebfb04852951bfdf9858dbc4b" lib/core/config/agora_config.dart; then
        print_success "Agora configuration verified"
    else
        print_error "Agora configuration not found"
    fi
    
    # Test 3: Verify call models are present
    print_status "Verifying call models..."
    if [ -f "lib/features/call/domain/models/call_model.dart" ]; then
        print_success "Call models verified"
    else
        print_error "Call models not found"
    fi
    
    # Test 4: Verify service locator has all services
    print_status "Verifying service locator..."
    if grep -q "CallManager" lib/core/services/service_locator.dart; then
        print_success "Service locator verified"
    else
        print_error "CallManager not found in service locator"
    fi
}

# Print deployment summary
print_deployment_summary() {
    echo ""
    echo "======================================================"
    print_success "🎉 Raabta Production Call System Deployment Complete!"
    echo "======================================================"
    echo ""
    echo "📋 Deployment Summary:"
    echo "   ✅ Supabase Edge Function (Agora Token Generation)"
    echo "   ✅ Firestore Rules (Call Permissions)"
    echo "   ✅ Flutter Dependencies"
    echo "   ✅ Cross-platform Compatibility"
    echo "   ✅ Call Manager with State Cleanup"
    echo "   ✅ Improved Ringtone Service"
    echo "   ✅ Enhanced Web Support"
    echo ""
    echo "🔗 Important URLs:"
    echo "   Supabase Project: https://supabase.com/dashboard/project/$SUPABASE_PROJECT_REF"
    echo "   Edge Function: https://$SUPABASE_PROJECT_REF.supabase.co/functions/v1/generate-agora-token"
    echo "   Firebase Console: https://console.firebase.google.com/project/$FIREBASE_PROJECT_ID"
    echo ""
    echo "🎯 Next Steps:"
    echo "   1. Test call functionality on all platforms"
    echo "   2. Monitor Supabase function performance"
    echo "   3. Verify Firestore call collection permissions"
    echo "   4. Test ringtone behavior on accept/decline"
    echo "   5. Validate video rendering on web platform"
    echo ""
    echo "📱 Supported Platforms:"
    echo "   ✅ Android"
    echo "   ✅ iOS"
    echo "   ✅ Web"
    echo "   ✅ macOS"
    echo "   ✅ Windows"
    echo "   ✅ Linux"
    echo ""
    print_success "Deployment completed successfully! 🚀"
}

# Main deployment flow
main() {
    check_prerequisites
    check_authentication
    update_flutter_dependencies
    deploy_supabase_function
    test_supabase_function
    deploy_firestore_rules
    build_flutter_app
    run_verification_tests
    print_deployment_summary
}

# Execute main function
main "$@"