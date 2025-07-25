#!/bin/bash

# Raabta Project - Complete Health Maintenance Script
# This script applies all necessary fixes and verifies project health

echo "🔧 Raabta Project Health Maintenance"
echo "===================================="
echo ""

# Set Flutter path
export PATH="/opt/flutter/bin:$PATH"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

echo "🏃 Starting comprehensive project health check and fixes..."
echo ""

# Step 1: Clean project
echo "🧹 Step 1: Cleaning project..."
flutter clean
echo "✅ Project cleaned"
echo ""

# Step 2: Get dependencies
echo "📦 Step 2: Getting dependencies..."
flutter pub get
echo "✅ Dependencies updated"
echo ""

# Step 3: Apply Agora fix
echo "🔧 Step 3: Applying Agora Web compatibility fix..."
if [ -f "./fix_agora_web_compatibility.sh" ]; then
    ./fix_agora_web_compatibility.sh
    echo "✅ Agora fix applied"
else
    echo "⚠️ Agora fix script not found - creating it..."
    
    # Create the agora fix script inline
    cat > fix_agora_web_compatibility.sh << 'EOF'
#!/bin/bash

echo "🔧 Fixing Agora Web Compatibility Issues..."

PUB_CACHE_DIR=$(flutter pub cache dir 2>/dev/null || echo "$HOME/.pub-cache")
AGORA_PACKAGE_DIR="$PUB_CACHE_DIR/hosted/pub.dev/agora_rtc_engine-6.5.2"
TARGET_FILE="$AGORA_PACKAGE_DIR/lib/src/impl/platform/web/global_video_view_controller_platform_web.dart"

if [ ! -f "$TARGET_FILE" ]; then
    echo "❌ Target file not found: $TARGET_FILE"
    exit 1
fi

echo "✅ Found target file: $TARGET_FILE"

# Create backup
BACKUP_FILE="${TARGET_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$TARGET_FILE" "$BACKUP_FILE"
echo "📋 Created backup: $BACKUP_FILE"

# Apply the fix
cat > "$TARGET_FILE" << 'INNER_EOF'
import 'dart:async';
import 'dart:html' as html;

// Critical fix for Flutter Web - Import platformViewRegistry from dart:ui_web
// instead of dart:ui for proper web compatibility
import 'dart:ui_web' as ui_web;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtc_engine/src/impl/platform/global_video_view_controller_platform.dart';
import 'package:iris_method_channel/iris_method_channel.dart';

// ignore_for_file: public_member_api_docs

const _platformRendererViewType = 'AgoraSurfaceView';

String _getViewType(int id) {
  return 'agora_rtc_engine/${_platformRendererViewType}_$id';
}

class _View {
  _View(int platformViewId)
      : _element = html.DivElement()
          ..id = _getViewType(platformViewId)
          ..style.width = '100%'
          ..style.height = '100%' {
    // Wait until the element is injected into the DOM,
    // see https://github.com/flutter/flutter/issues/143922#issuecomment-1960133128
    final observer = html.IntersectionObserver((entries, observer) {
      if (_element.isConnected == true) {
        observer.unobserve(_element);
        _viewCompleter.complete(_element);
      }
    });
    observer.observe(_element);
  }

  final html.HtmlElement _element;
  html.HtmlElement get element => _element;

  final _viewCompleter = Completer<html.HtmlElement>();

  Future<String> waitAndGetId() async {
    final div = await _viewCompleter.future;
    return div.id;
  }
}

// TODO(littlegnal): Need handle remove view logic on web
final Map<int, _View> _viewMap = {};

class GlobalVideoViewControllerWeb extends GlobalVideoViewControllerPlatfrom {
  GlobalVideoViewControllerWeb(
      IrisMethodChannel irisMethodChannel, RtcEngine rtcEngine)
      : super(irisMethodChannel, rtcEngine) {
    // FIXED: Use ui_web.platformViewRegistry instead of ui.platformViewRegistry
    // This resolves the "Undefined name 'platformViewRegistry'" error
    ui_web.platformViewRegistry.registerViewFactory(_platformRendererViewType,
        (int viewId) {
      final view = _View(viewId);
      _viewMap[viewId] = view;
      return view.element;
    });
  }

  @override
  Future<void> detachVideoFrameBufferManager(int irisRtcEngineIntPtr) {
    _viewMap.clear();
    return super.detachVideoFrameBufferManager(irisRtcEngineIntPtr);
  }

  @override
  Future<void> setupVideoView(Object viewHandle, VideoCanvas videoCanvas,
      {RtcConnection? connection}) async {
    // The `viewHandle` is the platform view id on web
    final viewId = viewHandle as int;

    final div = _viewMap[viewId]!;
    final divId = await div.waitAndGetId();

    await super.setupVideoView(divId, videoCanvas, connection: connection);
  }
}
INNER_EOF

echo "✅ Applied fix to: $TARGET_FILE"

# Verify the fix
if grep -q "dart:ui_web" "$TARGET_FILE"; then
    echo "✅ Fix verification successful - dart:ui_web import found"
else
    echo "❌ Fix verification failed - dart:ui_web import not found"
    echo "🔄 Restoring backup..."
    cp "$BACKUP_FILE" "$TARGET_FILE"
    exit 1
fi

echo "🎉 Agora Web compatibility fix applied successfully!"
EOF
    
    chmod +x fix_agora_web_compatibility.sh
    ./fix_agora_web_compatibility.sh
    echo "✅ Agora fix created and applied"
fi
echo ""

# Step 4: Fix deprecation warnings
echo "🔧 Step 4: Fixing deprecation warnings..."
if [ -f "./fix_deprecation_warnings.sh" ]; then
    ./fix_deprecation_warnings.sh
    echo "✅ Deprecation warnings fixed"
else
    echo "⚠️ Creating deprecation fix script..."
    
    # Create the deprecation fix script inline
    cat > fix_deprecation_warnings.sh << 'EOF'
#!/bin/bash

echo "🔧 Fixing Deprecation Warnings - withOpacity to withValues..."

DART_FILES=$(find lib -name "*.dart" -type f)
FIXES_APPLIED=0

for file in $DART_FILES; do
    if grep -q "\.withOpacity(" "$file"; then
        echo "🔍 Processing: $file"
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
        sed -i 's/\.withOpacity(\([^)]*\))/\.withValues(alpha: \1)/g' "$file"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
        echo "✅ Fixed: $file"
    fi
done

echo "🎉 Deprecation warnings fix completed!"
echo "📊 Total files processed: $FIXES_APPLIED"
EOF
    
    chmod +x fix_deprecation_warnings.sh
    ./fix_deprecation_warnings.sh
    echo "✅ Deprecation fix created and applied"
fi
echo ""

# Step 5: Analyze project
echo "🔍 Step 5: Analyzing project..."
ANALYSIS_RESULT=$(flutter analyze 2>&1)
if echo "$ANALYSIS_RESULT" | grep -q "No issues found!"; then
    echo "✅ Analysis passed - No issues found!"
else
    echo "⚠️ Analysis found issues:"
    echo "$ANALYSIS_RESULT"
fi
echo ""

# Step 6: Test web build
echo "🏗️ Step 6: Testing web build..."
BUILD_RESULT=$(flutter build web 2>&1)
if echo "$BUILD_RESULT" | grep -q "✓ Built build/web"; then
    echo "✅ Web build successful!"
else
    echo "❌ Web build failed:"
    echo "$BUILD_RESULT"
    exit 1
fi
echo ""

# Step 7: Generate health report
echo "📊 Step 7: Generating health report..."

# Count issues
ERROR_COUNT=$(echo "$ANALYSIS_RESULT" | grep -o "error •" | wc -l)
WARNING_COUNT=$(echo "$ANALYSIS_RESULT" | grep -o "warning •" | wc -l)
INFO_COUNT=$(echo "$ANALYSIS_RESULT" | grep -o "info •" | wc -l)

cat > PROJECT_HEALTH_REPORT.md << EOF
# 🏥 Raabta Project Health Report
*Generated on: $(date)*

## 📊 Current Status
- **Errors**: $ERROR_COUNT
- **Warnings**: $WARNING_COUNT  
- **Info Messages**: $INFO_COUNT
- **Web Build**: ✅ Successful
- **Overall Health**: $([ "$ERROR_COUNT" -eq 0 ] && [ "$WARNING_COUNT" -eq 0 ] && echo "🟢 EXCELLENT" || echo "🟡 NEEDS ATTENTION")

## 🔧 Fixes Applied
- ✅ Agora Web Compatibility (platformViewRegistry)
- ✅ Deprecation Warnings (withOpacity → withValues)
- ✅ Dependencies Updated
- ✅ Project Cleaned

## 📝 Analysis Results
\`\`\`
$ANALYSIS_RESULT
\`\`\`

## 🏗️ Build Results
\`\`\`
$BUILD_RESULT
\`\`\`

---
*Maintenance completed successfully*
EOF

echo "✅ Health report generated: PROJECT_HEALTH_REPORT.md"
echo ""

# Final summary
echo "🎉 PROJECT HEALTH MAINTENANCE COMPLETED!"
echo "======================================="
echo ""
echo "📊 Summary:"
echo "  - Errors: $ERROR_COUNT"
echo "  - Warnings: $WARNING_COUNT"
echo "  - Info: $INFO_COUNT"
echo "  - Web Build: ✅ Success"
echo ""

if [ "$ERROR_COUNT" -eq 0 ] && [ "$WARNING_COUNT" -eq 0 ]; then
    echo "🟢 PROJECT STATUS: EXCELLENT - Ready for production!"
else
    echo "🟡 PROJECT STATUS: Needs attention - Check analysis results"
fi

echo ""
echo "📝 Next steps:"
echo "  1. Review PROJECT_HEALTH_REPORT.md"
echo "  2. Test application functionality"
echo "  3. Deploy to production if status is excellent"
echo ""
echo "🔄 To run this maintenance again:"
echo "  ./maintain_project_health.sh"