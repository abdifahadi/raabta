// Stub for dart:html when not on web platform

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

// Audio API stubs for non-web platforms
class AudioContext {
  String get state => 'running';
  num? get currentTime => 0;
  AudioDestinationNode? get destination => AudioDestinationNode();
  
  GainNode createGain() => GainNode();
  OscillatorNode createOscillator() => OscillatorNode();
  
  Future<void> resume() async {}
  Future<void> suspend() async {}
  Future<void> close() async {}
}

class AudioDestinationNode {}

class GainNode {
  AudioParam? get gain => AudioParam();
  void connectNode(dynamic destination) {}
}

class OscillatorNode {
  AudioParam? get frequency => AudioParam();
  String type = 'sine';
  
  void connectNode(dynamic destination) {}
  void start(num when) {}
  void stop(num when) {}
}

class AudioParam {
  num value = 0;
  void setValueAtTime(num value, num time) {}
  void linearRampToValueAtTime(num value, num time) {}
}

final Window window = Window();
