import Cocoa
import FlutterMacOS
import AVFoundation

@main
class AppDelegate: FlutterAppDelegate {
  private var audioPlayer: AVAudioPlayer?
  private let CHANNEL = "ringtone_service"
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    let ringtoneChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.engine.binaryMessenger)
    
    ringtoneChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "startRingtone":
        self?.startRingtone()
        result(nil)
      case "stopRingtone":
        self?.stopRingtone()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  private func startRingtone() {
    guard audioPlayer?.isPlaying != true else { return }
    
    do {
      // Use system alert sound or a custom sound file
      if let soundPath = Bundle.main.path(forResource: "ringtone", ofType: "mp3") {
        let soundUrl = URL(fileURLWithPath: soundPath)
        audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
        audioPlayer?.numberOfLoops = -1 // Loop indefinitely
        audioPlayer?.play()
      } else {
        // Fallback to system sound
        NSSound.beep()
      }
    } catch {
      print("Error playing ringtone: \(error)")
      NSSound.beep()
    }
  }
  
  private func stopRingtone() {
    audioPlayer?.stop()
    audioPlayer = nil
  }
}
