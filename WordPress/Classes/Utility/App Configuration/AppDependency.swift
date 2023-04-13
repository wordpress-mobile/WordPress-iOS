import Foundation

/// - Warning:
/// This configuration class has a **Jetpack** counterpart in the Jetpack bundle.
/// Make sure to keep them in sync to avoid build errors when building the Jetpack target.
@objc class AppDependency: NSObject {
    static func authenticationManager(windowManager: WindowManager) -> WordPressAuthenticationManager {
        return WordPressAuthenticationManager(
            windowManager: windowManager,
            remoteFeaturesStore: RemoteFeatureFlagStore()
        )
    }

    static func windowManager(window: UIWindow) -> WindowManager {
        return WindowManager(window: window)
    }
}
