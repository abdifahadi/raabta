// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// Web-specific video view implementation
class PlatformVideoView extends StatefulWidget {
  final RtcEngine engine;
  final int uid;
  final bool isLocal;
  final String? channelId;

  const PlatformVideoView({
    super.key,
    required this.engine,
    required this.uid,
    required this.isLocal,
    this.channelId,
  });

  @override
  State<PlatformVideoView> createState() => _PlatformVideoViewState();
}

class _PlatformVideoViewState extends State<PlatformVideoView> {
  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('🌐 Creating web video view for UID: ${widget.uid}, isLocal: ${widget.isLocal}');
    }

    try {
      if (widget.isLocal) {
        return AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: widget.engine,
            canvas: const VideoCanvas(
              uid: 0,
              renderMode: RenderModeType.renderModeHidden,
              mirrorMode: VideoMirrorModeType.videoMirrorModeAuto,
            ),
          ),
          onAgoraVideoViewCreated: (viewId) {
            if (kDebugMode) {
              debugPrint('🎬 Web local video view created with ID: $viewId');
            }
          },
        );
      } else {
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: widget.engine,
            canvas: VideoCanvas(
              uid: widget.uid,
              renderMode: RenderModeType.renderModeHidden,
              mirrorMode: VideoMirrorModeType.videoMirrorModeDisabled,
            ),
            connection: widget.channelId != null 
                ? RtcConnection(channelId: widget.channelId!)
                : const RtcConnection(),
          ),
          onAgoraVideoViewCreated: (viewId) {
            if (kDebugMode) {
              debugPrint('🎬 Web remote video view created for UID: ${widget.uid}, View ID: $viewId');
            }
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Web video view error: $e');
      }
      
      // Fallback for web platforms
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isLocal ? Icons.videocam_off : Icons.person,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isLocal ? 'Local Video' : 'Remote Video',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 4),
                Text(
                  'Error: $e',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }
  }
}