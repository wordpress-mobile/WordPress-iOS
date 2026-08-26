import BuildSettingsKit
import Foundation
import SwiftUI
import UIKit

let isRunningTests = NSClassFromString("XCTestCase") != nil
let appDelegateClass =
    isRunningTests ? NSStringFromClass(TestingAppDelegate.self) : NSStringFromClass(WordPressAppDelegate.self)

// The secrets MUST be configured before the app launches.
//
// This is because `BuildSettings` are not propagated through the app via chain injection but accessed via a `static` `current` property for convenience.
// Also for convenience, we assume the secrets not to be nil at runtime, to avoid unwrapping values that we know must be there.
// Therefore, we need to make the secrets available to `BuildSettings` before the app starts.
BuildSettings.configure(secrets: ApiCredentials.toSecrets())

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    appDelegateClass
)

final class TestingAppDelegate: NSObject, UIApplicationDelegate {
    /// Opt the unit test host into the UIScene life cycle. iOS 27 removed the legacy
    /// window life cycle, so a plain `UIWindow()` created here crashes the host at launch.
    /// Mirrors `WordPressAppDelegate`'s programmatic scene opt-in.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        if connectingSceneSession.role == .windowApplication {
            configuration.delegateClass = TestingSceneDelegate.self
        }
        return configuration
    }
}

final class TestingSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: TestingRootView())
        window.makeKeyAndVisible()
        self.window = window
    }
}

private struct TestingRootView: View {
    var body: some View {
        Text("Running unit tests")
    }
}
