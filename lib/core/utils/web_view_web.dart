import "dart:html" show DivElement;
import 'dart:ui' as ui;
import '../../utils/universal_platform_view_registry.dart';

@pragma('dart2js:tryInline')
void registerWebView() {
  final localVideo = DivElement()
    ..style.border = "none"
    ..id = "local-video"
    ..style.width = "100%"
    ..style.height = "100%";

  // Use the universal platform view registry for safe registration
  UniversalPlatformViewRegistry.registerViewFactory(
    "local-video-view",
    (int viewId) => localVideo,
  );
}