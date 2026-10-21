import Flutter
import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  // Stash a cold-launch shortcut so we can fire it once Dart is ready (in
  // sceneDidBecomeActive). Forwarding straight from willConnectTo would race
  // the Flutter engine before the QuickActionsService listener is set up.
  private var pendingShortcut: UIApplicationShortcutItem?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }
    window = UIWindow(windowScene: windowScene)
    let controller = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    controller.loadDefaultSplashScreenView()
    window?.rootViewController = controller
    window?.makeKeyAndVisible()

    // Forward any cold-launch URL (e.g. from a home screen widget tap) to the
    // AppDelegate so registered Flutter plugins like home_widget can receive it.
    if let url = connectionOptions.urlContexts.first?.url {
      _ = UIApplication.shared.delegate?.application?(UIApplication.shared, open: url, options: [:])
    }

    // Cold-launch via app-icon long-press shortcut. iOS delivers it here for
    // scene-based apps, NOT through the app delegate's launchOptions. Stash
    // it and play it back in sceneDidBecomeActive so the Flutter engine is
    // ready by the time we forward to plugins.
    if let shortcut = connectionOptions.shortcutItem {
      pendingShortcut = shortcut
    }
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    _ = UIApplication.shared.delegate?.application?(UIApplication.shared, open: url, options: [:])
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    if let shortcut = pendingShortcut {
      pendingShortcut = nil
      forwardShortcut(shortcut)
    }

    // This scene is now the foreground process. Claim audio ownership and tell
    // any background process (e.g. one a widget play intent launched) to stop,
    // so two streams can't overlap (#285).
    (UIApplication.shared.delegate as? AppDelegate)?.claimAudioOwnershipAndNotifyOthers()

    // A book already mixing with another app gets its lock screen card now:
    // iOS starts Live Activities only for an app in the foreground.
    BookLiveActivityController.refresh(reason: "foreground")
  }

  // Warm-launch via shortcut. iOS 13+ scene-based apps get the shortcut here
  // rather than on the app delegate.
  func windowScene(_ windowScene: UIWindowScene,
                   performActionFor shortcutItem: UIApplicationShortcutItem,
                   completionHandler: @escaping (Bool) -> Void) {
    forwardShortcut(shortcutItem)
    completionHandler(true)
  }

  /// Forward a shortcut tap to the AppDelegate so its registered Flutter
  /// plugins (notably quick_actions_ios) can pick it up. iOS only calls
  /// this method on the actual scene delegate, so the plugin's own scene
  /// handler never fires unless we relay it here.
  private func forwardShortcut(_ shortcut: UIApplicationShortcutItem) {
    _ = UIApplication.shared.delegate?.application?(
      UIApplication.shared,
      performActionFor: shortcut,
      completionHandler: { _ in }
    )
  }
}
