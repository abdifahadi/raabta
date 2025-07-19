#!/bin/bash

# Enhanced Raabta Web Build and Serve Script
# This script builds the Flutter web app and serves it locally with comprehensive checks

set -e

echo "🚀 Enhanced Raabta Web Build and Serve Script"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if Flutter is installed
print_status "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    print_error "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

print_success "Flutter found: $(flutter --version | head -n 1)"

# Check Flutter doctor for web
print_status "Checking Flutter web setup..."
if ! flutter doctor | grep -q "Chrome"; then
    print_warning "Chrome not detected by Flutter doctor"
    print_warning "Web debugging might be limited"
fi

# Check if pubspec.yaml exists
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Are you in the Flutter project directory?"
    exit 1
fi

# Check Firebase configuration
print_status "Checking Firebase configuration..."

# Check if firebase_options.dart exists
if [ ! -f "lib/core/config/firebase_options.dart" ]; then
    print_error "Firebase options file not found at lib/core/config/firebase_options.dart"
    print_error "Please run 'flutterfire configure' to set up Firebase"
    exit 1
else
    print_success "Firebase options file found"
fi

# Check web index.html for Firebase scripts
if grep -q "firebase-app-compat.js" web/index.html; then
    print_success "Firebase scripts found in web/index.html"
else
    print_warning "Firebase scripts not found in web/index.html"
    print_warning "This might cause Firebase initialization issues on web"
fi

# Clean and get dependencies
print_status "Cleaning project and getting dependencies..."
flutter clean
flutter pub get

# Check for any immediate issues
print_status "Running quick health check..."
flutter analyze --no-fatal-infos

# Build for web with optimizations
print_status "Building Flutter web app..."
print_status "Build mode: Release (optimized for production)"

# Build with web-specific optimizations
flutter build web \
    --web-renderer html \
    --csp \
    --source-maps \
    --dart-define=FLUTTER_WEB_USE_SKIA=false \
    --dart-define=FLUTTER_WEB_AUTO_DETECT=false

if [ $? -eq 0 ]; then
    print_success "Web build completed successfully!"
    
    # Display build information
    echo ""
    echo "📊 Build Information:"
    echo "===================="
    echo "📁 Output directory: build/web/"
    echo "🎯 Renderer: HTML"
    echo "🔒 CSP enabled: Yes"
    echo "🗺️  Source maps: Yes"
    echo "📱 Auto-detect: Disabled"
    echo "🎨 Skia: Disabled (HTML renderer)"
    
    # Check build size
    if [ -d "build/web" ]; then
        build_size=$(du -sh build/web | cut -f1)
        echo "📦 Build size: $build_size"
    fi
    
    echo ""
else
    print_error "Web build failed!"
    print_error "Please check the error messages above and fix any issues"
    exit 1
fi

# Check if we should serve the app
read -p "🤔 Do you want to serve the app locally? (y/N): " serve_choice

if [[ $serve_choice =~ ^[Yy]$ ]]; then
    print_status "Starting local web server..."
    
    # Check if python3 is available
    if command -v python3 &> /dev/null; then
        print_status "Using Python 3 HTTP server"
        echo ""
        print_success "🌐 Web app will be available at: http://localhost:8000"
        print_success "📱 Mobile access: http://[your-ip]:8000"
        print_status "Press Ctrl+C to stop the server"
        echo ""
        
        cd build/web
        python3 -m http.server 8000
        
    elif command -v python &> /dev/null; then
        print_status "Using Python 2 HTTP server"
        echo ""
        print_success "🌐 Web app will be available at: http://localhost:8000"
        print_success "📱 Mobile access: http://[your-ip]:8000"
        print_status "Press Ctrl+C to stop the server"
        echo ""
        
        cd build/web
        python -m SimpleHTTPServer 8000
        
    else
        print_warning "Python not found. Cannot start local server."
        print_status "You can serve the files from build/web/ using any HTTP server"
        print_status "Example: 'cd build/web && python3 -m http.server 8000'"
    fi
else
    print_success "Build completed! Files are in build/web/"
    print_status "To serve manually:"
    print_status "  cd build/web"
    print_status "  python3 -m http.server 8000"
    print_status "  Then open http://localhost:8000"
fi

echo ""
print_success "✨ Script completed!"