import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.makaut_scholar/screen_security",
                                      binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "enableSecure" {
        self.enableSecure()
        result(true)
      } else if call.method == "disableSecure" {
        self.disableSecure()
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private var secureField: UITextField?

  private func enableSecure() {
    // iOS doesn't have FLAG_SECURE like Android. 
    // A common trick is to use a hidden UITextField with isSecureTextEntry = true.
    if secureField == nil {
      secureField = UITextField()
      secureField?.isSecureTextEntry = true
      if let view = window?.rootViewController?.view {
        view.addSubview(secureField!)
        secureField?.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        secureField?.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        // The secure field hack blocks screenshots and screen recordings of the entire window for some views
        // though it's more of a side effect. For Academic app, we can also use:
        window?.layer.contents = nil 
      }
    }
    
    // Better way for academic resources: Block screen recording
    NotificationCenter.default.addObserver(self, selector: #selector(screenCaptureChanged), name: UIScreen.capturedDidChangeNotification, object: nil)
  }

  private func disableSecure() {
    secureField?.removeFromSuperview()
    secureField = nil
    NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
  }

  @objc private func screenCaptureChanged() {
    if UIScreen.main.isCaptured {
      // Screen is being recorded or mirrored
      window?.isHidden = true
    } else {
      window?.isHidden = false
    }
  }
}
