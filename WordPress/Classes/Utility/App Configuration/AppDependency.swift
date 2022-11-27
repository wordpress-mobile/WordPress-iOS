import Foundation

/// - Warning:
/// This configuartion class has a **Jetpack** counterpart in the Jetpack bundle.
/// Make sure to keep them in sync to avoid build errors when builing the Jetpack target.
@objc class AppDependency: NSObject {
    static func authenticationManager(windowManager: WindowManager) -> WordPressAuthenticationManager {
        return WordPressAuthenticationManager(windowManager: windowManager)
    }

    static func windowManager(window: UIWindow) -> WindowManager {
        return WindowManager(window: window)
    }
}
