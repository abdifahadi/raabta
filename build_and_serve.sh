#!/bin/bash

# Raabta Web Build and Serve Script
# This script builds the Flutter web app and serves it locally

set -e

echo "🚀 Building and serving Raabta web app..."

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
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    print_status "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

print_success "Flutter found: $(flutter --version | head -1)"

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    print_error "This doesn't appear to be a Flutter project (no pubspec.yaml found)"
    exit 1
fi

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Analyze code
print_status "Analyzing code..."
if flutter analyze --no-fatal-infos; then
    print_success "Code analysis passed"
else
    print_warning "Code analysis found issues, but continuing..."
fi

# Build for web
print_status "Building for web..."
if flutter build web --release; then
    print_success "Web build completed successfully"
else
    print_error "Web build failed"
    exit 1
fi

# Check if build directory exists
if [ ! -d "build/web" ]; then
    print_error "Build directory not found"
    exit 1
fi

# Find an available port
PORT=8080
while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; do
    PORT=$((PORT + 1))
done

print_status "Using port $PORT"

# Serve the application
print_status "Starting web server..."
cd build/web

# Try different methods to serve the files
if command -v python3 &> /dev/null; then
    print_success "Starting Python HTTP server on http://localhost:$PORT"
    echo ""
    echo "🌐 Open your browser and go to: http://localhost:$PORT"
    echo "📱 For mobile testing, use your computer's IP address"
    echo "🛑 Press Ctrl+C to stop the server"
    echo ""
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    print_success "Starting Python HTTP server on http://localhost:$PORT"
    echo ""
    echo "🌐 Open your browser and go to: http://localhost:$PORT"
    echo "📱 For mobile testing, use your computer's IP address"
    echo "🛑 Press Ctrl+C to stop the server"
    echo ""
    python -m SimpleHTTPServer $PORT
elif command -v node &> /dev/null && command -v npx &> /dev/null; then
    print_success "Starting Node.js HTTP server on http://localhost:$PORT"
    echo ""
    echo "🌐 Open your browser and go to: http://localhost:$PORT"
    echo "📱 For mobile testing, use your computer's IP address"
    echo "🛑 Press Ctrl+C to stop the server"
    echo ""
    npx serve -s . -l $PORT
else
    print_error "No suitable HTTP server found"
    print_status "Please install Python or Node.js to serve the files"
    print_status "Alternatively, you can use any other HTTP server to serve the files in build/web/"
    exit 1
fi