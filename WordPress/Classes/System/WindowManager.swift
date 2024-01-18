import Foundation
import WordPressAuthenticator

/// This class takes care of managing the App window and its `rootViewController`.
/// This is mostly intended to handle the UI transitions between authenticated and unauthenticated user sessions.
///
@objc
class WindowManager: NSObject {

    typealias Completion = () -> Void

    /// The App's window.
    ///
    private let window: UIWindow

    /// Temporary window that's displayed on top of the app's UI when needed.
    ///
    private var overlayingWindow: UIWindow?

    /// A boolean to track whether we're showing the sign in flow in fullscreen mode..
    ///
    private(set) var isShowingFullscreenSignIn = false

    /// The root view controller for the window.
    ///
    var rootViewController: UIViewController? {
        return window.rootViewController
    }

    init(window: UIWindow) {
        self.window = window
    }

    // MARK: - Initial App UI

    /// Shows the initial UI for the App to be shown right after launch.  This method will present the sign-in flow if the user is not
    /// authenticated, or the actuall App UI if the user is already authenticated.
    ///
    public func showUI(for blog: Blog? = nil, animated: Bool = true) {
        if AccountHelper.isLoggedIn {
            showAppUI(for: blog, animated: animated)
        } else {
            showSignInUI()
        }
    }

    /// Shows the SignIn UI flow if the conditions to do so are met.
    ///
    @objc
    func showFullscreenSignIn() {
        guard isShowingFullscreenSignIn == false && AccountHelper.isLoggedIn == false else {
            return
        }

        showSignInUI()
    }

    func dismissFullscreenSignIn(blogToShow: Blog? = nil, completion: Completion? = nil) {
        guard isShowingFullscreenSignIn == true && AccountHelper.isLoggedIn == true else {
            return
        }

        showAppUI(for: blogToShow, completion: completion)
    }

    /// Shows the UI for authenticated users.
    ///
    @objc func showAppUI(for blog: Blog? = nil, animated: Bool = true, completion: Completion? = nil) {
        isShowingFullscreenSignIn = false
        RootViewCoordinator.shared.showAppUI(animated: animated, completion: completion)

        guard let blog = blog else {
            return
        }

        RootViewCoordinator.sharedPresenter.showBlogDetails(for: blog)
    }

    /// Shows the initial UI for unauthenticated users.
    ///
    func showSignInUI(completion: Completion? = nil) {
        isShowingFullscreenSignIn = true

        RootViewCoordinator.shared.showSignInUI(completion: completion)
    }

    /// Shows the specified VC as the root VC for the managed window.  Takes care of animating the transition whenever the existing
    /// root VC isn't `nil` (this is because a `nil` VC means we're showing the initial VC on a call to this method).
    ///
    func show(_ viewController: UIViewController, animated: Bool = true, completion: Completion? = nil) {
        // When the App is launched, the root VC will be `nil`.
        // When this is the case we'll simply show the VC without any type of animation.
        guard window.rootViewController != nil, animated else {
            window.rootViewController = viewController
            return
        }

        window.rootViewController = viewController

        UIView.transition(
            with: window,
            duration: WPAnimationDurationDefault,
            options: .transitionCrossDissolve,
            animations: nil,
            completion: { _ in
                completion?()
            })
    }

    // MARK: Temporary Overlaying Window

    /// Creates a window with the passed root view and displays it on top of the app's UI.
    /// - Parameter rootViewController: View controller to be used as the root view controller for the newly created window.
    ///
    func displayOverlayingWindow(with rootViewController: UIViewController) {
        clearOverlayingWindow()
        let windowFrame = window.frame
        let window = UIWindow(frame: windowFrame)
        window.rootViewController = rootViewController
        window.windowLevel = .alert
        window.isHidden = false
        window.makeKeyAndVisible()
        overlayingWindow = window
    }

    /// Removes the temporary overlaying window if it exists. And makes the main window the key window again.
    ///
    func clearOverlayingWindow() {
        guard let overlayingWindow = overlayingWindow else {
            return
        }
        overlayingWindow.isHidden = true
        self.overlayingWindow = nil
        window.makeKey()
    }
}
