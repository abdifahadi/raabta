import Flutter
import UIKit
import AVFoundation
import AudioToolbox

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioPlayer: AVAudioPlayer?
  private let CHANNEL = "ringtone_service"
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let controller = window?.rootViewController as! FlutterViewController
    let ringtoneChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)
    
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
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func startRingtone() {
    guard audioPlayer?.isPlaying != true else { return }
    
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
      
      // Use system ringtone sound
      if let soundPath = Bundle.main.path(forResource: "ringtone", ofType: "mp3") {
        let soundUrl = URL(fileURLWithPath: soundPath)
        audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
      } else {
        // Fallback to system sound
        AudioServicesPlaySystemSound(SystemSoundID(1005)) // Ringtone sound
        return
      }
      
      audioPlayer?.numberOfLoops = -1 // Loop indefinitely
      audioPlayer?.play()
    } catch {
      print("Error playing ringtone: \(error)")
      // Fallback to vibration
      AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
  }
  
  private func stopRingtone() {
    audioPlayer?.stop()
    audioPlayer = nil
    
    do {
      try AVAudioSession.sharedInstance().setActive(false)
    } catch {
      print("Error deactivating audio session: \(error)")
    }
  }
}
