// Stub for dart:html when not on web platform

class MediaStream {
  List<dynamic> getTracks() => [];
  List<dynamic> getAudioTracks() => [];
  List<dynamic> getVideoTracks() => [];
}

class Window {
  Navigator get navigator => Navigator();
}

class Navigator {
  MediaDevices? get mediaDevices => MediaDevices();
}

class MediaDevices {
  Future<MediaStream> getUserMedia(Map<String, dynamic> constraints) async {
    throw UnsupportedError('getUserMedia not supported on this platform');
  }
}

final Window window = Window();
