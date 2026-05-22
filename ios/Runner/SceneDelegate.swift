import Flutter
import UIKit
import UserNotifications

/// Scene-based apps deliver cold-start push taps through
/// `scene(_:willConnectTo:options:)` — NOT through the traditional
/// AppDelegate launchOptions path that Firebase swizzle reads.
/// `getInitialMessage()` therefore returns nil for these taps.
///
/// We capture the URL here and store it in UserDefaults under
/// `flutter.lpr_gate_tap_url`. The `flutter.` prefix is mandatory
/// because `shared_preferences` on iOS reads UserDefaults values using
/// that prefix, letting `NativeTapBridge.consumeTapUrl()` pick it up
/// through SharedPreferences with no MethodChannel dance.
class SceneDelegate: FlutterSceneDelegate {
  static let tapUrlKey = "flutter.lpr_gate_tap_url"

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    if let response = connectionOptions.notificationResponse,
       let url = SceneDelegate.extractUrl(
         from: response.notification.request.content.userInfo
       )
    {
      SceneDelegate.persist(url: url)
    }
  }

  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    super.scene(scene, continue: userActivity)
  }

  /// Checks every key the gray backend may use for the destination URL.
  static func extractUrl(from userInfo: [AnyHashable: Any]) -> String? {
    let keys = ["url", "link", "target", "deeplink", "deep_link"]

    func scan(_ map: [AnyHashable: Any]) -> String? {
      for key in keys {
        if let raw = map[key] as? String,
           !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }
      }
      return nil
    }

    if let direct = scan(userInfo) { return direct }
    if let nested = userInfo["payload"] as? [AnyHashable: Any] {
      return scan(nested)
    }
    return nil
  }

  static func persist(url: String) {
    NSLog("[LPR.NATIVE] cold-start tap url -> %@", url)
    let d = UserDefaults.standard
    d.set(url, forKey: tapUrlKey)
    d.synchronize()
  }
}
