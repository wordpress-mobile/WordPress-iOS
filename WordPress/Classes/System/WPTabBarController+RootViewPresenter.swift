import Foundation

/// `WPTabBarController` is used as the root presenter when Jetpack features are enabled
/// and the app's UI is normal.
extension WPTabBarController: RootViewPresenter {
    var rootViewController: UIViewController {
        return self
    }
}
