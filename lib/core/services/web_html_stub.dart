// Stub for web APIs when not on web platform

class Location {
  String protocol = 'https:';
  String? hostname = 'localhost';
}

class MediaStream {
  List<dynamic> getTracks() => [];
  List<dynamic> getAudioTracks() => [];
  List<dynamic> getVideoTracks() => [];
}

class Window {
  Navigator get navigator => Navigator();
  Location get location => Location();
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
