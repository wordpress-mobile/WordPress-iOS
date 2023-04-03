import Foundation

/// - Warning:
/// This configuration class has a **WordPress** counterpart in the WordPress bundle.
/// Make sure to keep them in sync to avoid build errors when builing the WordPress target.
@objc class AppDependency: NSObject {
    static func authenticationManager(windowManager: WindowManager) -> WordPressAuthenticationManager {
        return WordPressAuthenticationManager(
            windowManager: windowManager,
            authenticationHandler: JetpackAuthenticationManager(),
            remoteFeaturesStore: RemoteFeatureFlagStore()
        )
    }

    static func windowManager(window: UIWindow) -> WindowManager {
        return JetpackWindowManager(window: window)
    }
}
