import "dart:html" show DivElement;
import "dart:ui_web" as ui_web;

@pragma('dart2js:tryInline')
void registerWebView() {
  final localVideo = DivElement()
    ..style.border = "none"
    ..id = "local-video"
    ..style.width = "100%"
    ..style.height = "100%";

  ui_web.platformViewRegistry.registerViewFactory(
    "local-video-view",
    (int viewId) => localVideo,
  );
}