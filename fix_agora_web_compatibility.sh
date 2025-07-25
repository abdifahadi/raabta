#!/bin/bash

# Raabta - Agora Web Compatibility Fix Script
# This script fixes the platformViewRegistry issue in agora_rtc_engine 6.5.2
# for Flutter Web compatibility

echo "🔧 Fixing Agora Web Compatibility Issues..."

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Get pub cache directory
PUB_CACHE_DIR=$(flutter pub cache dir 2>/dev/null || echo "$HOME/.pub-cache")
AGORA_PACKAGE_DIR="$PUB_CACHE_DIR/hosted/pub.dev/agora_rtc_engine-6.5.2"
TARGET_FILE="$AGORA_PACKAGE_DIR/lib/src/impl/platform/web/global_video_view_controller_platform_web.dart"

echo "📁 Pub cache directory: $PUB_CACHE_DIR"
echo "📦 Agora package directory: $AGORA_PACKAGE_DIR"

# Check if agora package exists
if [ ! -d "$AGORA_PACKAGE_DIR" ]; then
    echo "❌ Agora RTC Engine package not found. Running flutter pub get first..."
    flutter pub get
    if [ ! -d "$AGORA_PACKAGE_DIR" ]; then
        echo "❌ Failed to download agora_rtc_engine package"
        exit 1
    fi
fi

# Check if target file exists
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
cat > "$TARGET_FILE" << 'EOF'
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
EOF

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
echo "📝 You can now run: flutter run -d web-server --web-port=8080"
echo ""
echo "Note: You may need to re-run this script after:"
echo "  - flutter clean"
echo "  - flutter pub get (if packages are re-downloaded)"
echo "  - Updating agora_rtc_engine package"