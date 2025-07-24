import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// Web-compatible wrapper for AgoraVideoView that handles platform differences
class AgoraVideoViewWeb extends StatefulWidget {
  final VideoViewController controller;
  final bool useHtmlElement;

  const AgoraVideoViewWeb({
    Key? key,
    required this.controller,
    this.useHtmlElement = true,
  }) : super(key: key);

  @override
  State<AgoraVideoViewWeb> createState() => _AgoraVideoViewWebState();
}

class _AgoraVideoViewWebState extends State<AgoraVideoViewWeb> {
  @override
  Widget build(BuildContext context) {
    if (kIsWeb && widget.useHtmlElement) {
      // On web, use a Container as placeholder for now
      // The actual video rendering will be handled by Agora's web SDK
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam,
                color: Colors.white54,
                size: 48,
              ),
              SizedBox(height: 8),
              Text(
                'Video View (Web)',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // For non-web platforms or fallback, use the original AgoraVideoView
    return AgoraVideoView(
      controller: widget.controller,
    );
  }
}

/// Utility function to create the appropriate video view based on platform
Widget createVideoView(VideoViewController controller) {
  if (kIsWeb) {
    return AgoraVideoViewWeb(controller: controller);
  }
  return AgoraVideoView(controller: controller);
}