import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let payload = response.notification.request.content.userInfo["payload"] as? String
    let actionId = response.actionIdentifier
    NSLog("[AppDelegate] didReceiveNotificationResponse: action=%@, payload=%@", actionId, payload ?? "nil")

    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)

    if let payload = payload, !payload.isEmpty {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        if let controller = self.window?.rootViewController as? FlutterViewController {
          let channel = FlutterMethodChannel(name: "lamontlabs.oly/deep_links", binaryMessenger: controller.binaryMessenger)
          channel.invokeMethod("onDeepLink", arguments: ["payload": payload, "actionId": actionId])
        }
      }
    }
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    NSLog("[AppDelegate] openURL: %@", url.absoluteString)
    if let controller = self.window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "lamontlabs.oly/deep_links", binaryMessenger: controller.binaryMessenger)
      channel.invokeMethod("onDeepLink", arguments: ["payload": url.absoluteString, "actionId": nil])
    }
    return super.application(app, open: url, options: options)
  }
}

