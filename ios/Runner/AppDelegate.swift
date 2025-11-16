import Flutter
import UIKit
import GoogleMaps

GMSServices.provideAPIKey("AIzaSyBNWlDsaLpp_0qKP6rOIENGuKerH_FViGE")
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
