import Foundation

@objc class AppDependency: NSObject {
    static func authenticationManager(windowManager: WindowManager) -> WordPressAuthenticationManager {
        return WordPressAuthenticationManager(windowManager: windowManager, authenticationHandler: JetpackAuthenticationManager())
    }

    static func windowManager(window: UIWindow) -> WindowManager {
        return JetpackWindowManager(window: window)
    }
}
