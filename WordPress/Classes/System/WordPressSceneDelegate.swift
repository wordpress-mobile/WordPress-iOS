import UIKit

/// The app's single-window scene delegate.
///
/// `WordPressAppDelegate` still owns `window` and `windowManager`; this delegate
/// creates the scene-attached window and forwards every scene callback into the
/// AppDelegate's shared handlers so the routing logic lives in one place.
@objc(WordPressSceneDelegate)
final class WordPressSceneDelegate: UIResponder, UIWindowSceneDelegate {

    private var appDelegate: WordPressAppDelegate? {
        UIApplication.shared.delegate as? WordPressAppDelegate
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        appDelegate?.showInitialUI(in: windowScene)

        // Drain any launch-time entry points the scene was created with.
        for context in connectionOptions.urlContexts {
            appDelegate?.handle(url: context.url)
        }
        for activity in connectionOptions.userActivities {
            appDelegate?.handle(userActivity: activity)
        }
        if let shortcutItem = connectionOptions.shortcutItem {
            _ = handle(shortcutItem: shortcutItem)
        }
    }

    // MARK: - Entry points

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            appDelegate?.handle(url: context.url)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        appDelegate?.handle(userActivity: userActivity)
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(handle(shortcutItem: shortcutItem))
    }

    /// Handles a Home Screen quick action. Returns whether the item was handled.
    private func handle(shortcutItem: UIApplicationShortcutItem) -> Bool {
        WP3DTouchShortcutHandler().handleShortcutItem(shortcutItem)
    }

    // MARK: - Activation

    func sceneDidBecomeActive(_ scene: UIScene) {
        appDelegate?.handleDidBecomeActive()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        appDelegate?.handleWillResignActive()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        appDelegate?.handleDidEnterBackground()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        appDelegate?.handleWillEnterForeground()
    }
}
