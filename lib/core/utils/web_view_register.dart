import "dart:html" show VideoElement;
import "dart:ui" as ui;
import "package:flutter/foundation.dart";

@pragma('dart2js:tryInline')
void registerWebView() {
  if (kIsWeb) {
    final localVideo = VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.border = "none"
      ..id = "local-video"
      ..style.width = "100%"
      ..style.height = "100%";

    ui.platformViewRegistry.registerViewFactory(
      "local-video-view",
      (int viewId) => localVideo,
    );
  }
}