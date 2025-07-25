import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// Cross-platform video view implementation for Agora RTC Engine 6.5.2+
/// Supports Android, iOS, Web, Windows, Linux, and macOS
class CrossPlatformVideoView extends StatefulWidget {
  final RtcEngine engine;
  final int uid;
  final bool isLocal;
  final String? channelId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CrossPlatformVideoView({
    super.key,
    required this.engine,
    required this.uid,
    this.isLocal = false,
    this.channelId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<CrossPlatformVideoView> createState() => _CrossPlatformVideoViewState();
}

class _CrossPlatformVideoViewState extends State<CrossPlatformVideoView> {
  bool _isVideoEnabled = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideoView();
  }

  Future<void> _initializeVideoView() async {
    try {
      if (kDebugMode) {
        debugPrint('🎬 CrossPlatformVideoView: Initializing video view');
        debugPrint('   UID: ${widget.uid}');
        debugPrint('   IsLocal: ${widget.isLocal}');
        debugPrint('   Platform: ${_getPlatformName()}');
      }

      // Video is enabled by default
      setState(() {
        _isVideoEnabled = true;
        _hasError = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CrossPlatformVideoView: Error initializing: $e');
      }
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: widget.borderRadius,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: _buildVideoView(),
      ),
    );
  }

  Widget _buildVideoView() {
    if (_hasError) {
      return _buildErrorView();
    }

    if (!_isVideoEnabled) {
      return _buildPlaceholderView();
    }

    try {
      if (widget.isLocal) {
        return _buildLocalVideoView();
      } else {
        return _buildRemoteVideoView();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CrossPlatformVideoView: Error building video view: $e');
      }
      return _buildErrorView();
    }
  }

  Widget _buildLocalVideoView() {
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
          debugPrint('🎬 CrossPlatformVideoView: Local video view created with ID: $viewId');
        }
      },
    );
  }

  Widget _buildRemoteVideoView() {
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
          debugPrint('🎬 CrossPlatformVideoView: Remote video view created for UID: ${widget.uid}, View ID: $viewId');
        }
      },
    );
  }

  Widget _buildPlaceholderView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isLocal ? Icons.videocam_off : Icons.person,
              color: Colors.white54,
              size: widget.width != null && widget.width! < 150 ? 32 : 48,
            ),
            const SizedBox(height: 8),
            Text(
              widget.isLocal ? 'Camera Off' : 'No Video',
              style: TextStyle(
                color: Colors.white54,
                fontSize: widget.width != null && widget.width! < 150 ? 10 : 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withOpacity(0.7),
              size: widget.width != null && widget.width! < 150 ? 24 : 32,
            ),
            const SizedBox(height: 4),
            Text(
              'Video Error',
              style: TextStyle(
                color: Colors.red.withOpacity(0.7),
                fontSize: widget.width != null && widget.width! < 150 ? 8 : 10,
              ),
              textAlign: TextAlign.center,
            ),
            if (kDebugMode && _errorMessage != null) ...[
              const SizedBox(height: 2),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.withOpacity(0.5),
                  fontSize: 8,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Update video enabled state
  void updateVideoState(bool enabled) {
    if (mounted) {
      setState(() {
        _isVideoEnabled = enabled;
      });
    }
  }

  /// Handle video errors
  void handleVideoError(String error) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error;
      });
    }
  }
}

/// Factory class for creating cross-platform video views
class CrossPlatformVideoViewFactory {
  /// Create a local video view
  static Widget createLocalVideoView({
    required RtcEngine engine,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return CrossPlatformVideoView(
      engine: engine,
      uid: 0,
      isLocal: true,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }

  /// Create a remote video view
  static Widget createRemoteVideoView({
    required RtcEngine engine,
    required int uid,
    String? channelId,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return CrossPlatformVideoView(
      engine: engine,
      uid: uid,
      isLocal: false,
      channelId: channelId,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }

  /// Create a placeholder view for when video is not available
  static Widget createPlaceholderView({
    required String label,
    IconData? icon,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: borderRadius,
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.videocam_off,
              color: Colors.white54,
              size: width != null && width < 150 ? 32 : 48,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white54,
                fontSize: width != null && width < 150 ? 10 : 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}