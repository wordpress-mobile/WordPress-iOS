import Foundation
import WordPressAuthenticator

/// This class takes care of managing the App window and its `rootViewController`.
/// This is mostly intended to handle the UI transitions between authenticated and unauthenticated user sessions.
///
@objc
class WindowManager: NSObject {

    /// The App's window.
    ///
    private let window: UIWindow

    /// A boolean to track whether we're showing the sign in flow.
    ///
    private var isSignInVisible = false

    init(window: UIWindow) {
        self.window = window
    }

    // MARK: - Initial App UI

    /// Shows the initial UI for the App to be shown right after launch.  This method will present the sign-in flow if the user is not
    /// authenticated, or the actuall App UI if the user is already authenticated.
    ///
    func showUI() {
        if AccountHelper.isLoggedIn {
            showUIForAuthenticatedUsers()
        } else {
            showUIForUnauthenticatedUsers()
        }
    }

    /// Shows the SignIn UI flow if the conditions to do so are met.
    ///
    @objc
    func showSignInIfNecessary() {
        guard isSignInVisible == false && AccountHelper.isLoggedIn == false else {
            return
        }

        showUIForUnauthenticatedUsers()
    }

    /// Shows the UI for authenticated users.
    ///
    func showUIForAuthenticatedUsers() {
        isSignInVisible = false

        show(WPTabBarController.sharedInstance())
    }

    /// Shows the initial UI for unauthenticated users.
    ///
    func showUIForUnauthenticatedUsers() {
        isSignInVisible = true

        guard let loginViewController = WordPressAuthenticator.loginUI() else {
            fatalError("No login UI to show to the user.  There's no way to gracefully handle this error.")
        }

        show(loginViewController)
    }

    /// Shows the specified VC as the root VC for the managed window.  Takes care of animating the transition whenever the existing
    /// root VC isn't `nil` (this is because a `nil` VC means we're showing the initial VC on a call to this method).
    ///
    private func show(_ viewController: UIViewController) {
        // When the App is launched, the root VC will be `nil`.
        // When this is the case we'll simply show the VC without any type of animation.
        guard window.rootViewController != nil else {
            window.rootViewController = viewController
            return
        }

        window.rootViewController = viewController

        UIView.transition(
            with: window,
            duration: WPAnimationDurationSlow,
            options: .transitionFlipFromBottom,
            animations: nil,
            completion: nil)
    }
}
