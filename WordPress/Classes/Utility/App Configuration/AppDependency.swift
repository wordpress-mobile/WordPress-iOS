import Foundation

@objc class AppDependency: NSObject {
    static func authenticationManager(windowManager: WindowManager) -> WordPressAuthenticationManager {
        return WordPressAuthenticationManager(windowManager: windowManager)
    }

    static func windowManager(window: UIWindow) -> WindowManager {
        return WindowManager(window: window)
    }
}
