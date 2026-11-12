import UIKit
import WordPressData

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
    private(set) var overlayingWindow: UIWindow?

    /// Called when the sign-in gate takes the overlaying window from the content it was showing.
    ///
    private var overlayingWindowReplacementHandler: (() -> Void)?

    /// Whether the overlaying window shows the sign-in gate. See `SignInGateCoordinator`.
    ///
    private var isShowingSignInGate = false

    /// Evaluates whether to show the sign-in gate when the app UI is shown.
    ///
    weak var signInGate: SignInGateCoordinator?

    /// A boolean to track whether we're showing the sign in flow in fullscreen mode..
    ///
    private(set) var isShowingFullscreenSignIn = false

    /// The root view controller for the window.
    ///
    var rootViewController: UIViewController? {
        window.rootViewController
    }

    init(window: UIWindow) {
        self.window = window
    }

    // MARK: - Initial App UI

    /// Shows the initial UI for the App to be shown right after launch. This method will present the sign-in flow if the user is not
    /// authenticated, or the actual App UI if the user is already authenticated.
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
    func showAppUI(for blog: Blog? = nil, animated: Bool = true, completion: Completion? = nil) {
        isShowingFullscreenSignIn = false
        RootViewCoordinator.shared.showAppUI(animated: animated, completion: completion)

        MainActor.assumeIsolated {
            signInGate?.evaluate(source: .launch)
        }

        guard let blog else {
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

    /// Shows the specified VC as the root VC for the managed window. Takes care of animating the transition whenever the existing
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
            duration: 0.33,
            options: .transitionCrossDissolve,
            animations: nil,
            completion: { _ in
                completion?()
            }
        )
    }

    // MARK: Temporary Overlaying Window

    /// Creates a window with the passed root view and displays it on top of the app's UI.
    ///
    /// Nothing is displayed while the sign-in gate is showing, because nothing may cover the gate.
    ///
    /// - Parameters:
    ///   - rootViewController: View controller to be used as the root view controller for the newly created window.
    ///   - onReplacedBySignInGate: Called if the sign-in gate later takes over the window. The passed view controller
    ///     is then removed without being dismissed.
    /// - Returns: Whether the window is displayed.
    ///
    @discardableResult
    func displayOverlayingWindow(
        with rootViewController: UIViewController,
        onReplacedBySignInGate: (() -> Void)? = nil
    ) -> Bool {
        guard !isShowingSignInGate else {
            return false
        }
        guard installOverlayingWindow(with: rootViewController) else {
            return false
        }
        overlayingWindowReplacementHandler = onReplacedBySignInGate
        return true
    }

    /// Removes the temporary overlaying window if it exists. And makes the main window the key window again.
    ///
    /// Does nothing while the window shows the sign-in gate, which only `dismissSignInGate()` removes.
    ///
    func clearOverlayingWindow() {
        guard !isShowingSignInGate else {
            return
        }
        removeOverlayingWindow()
    }

    /// Attaches the overlaying window to the given scene, which replaces the scene the system disconnected.
    ///
    /// Call this before making the main window key, along with attaching the main window to the scene.
    ///
    func reattachOverlayingWindow(to windowScene: UIWindowScene) {
        guard let overlayingWindow else {
            return
        }
        overlayingWindow.windowScene = windowScene
        overlayingWindow.isHidden = false
    }

    private func installOverlayingWindow(with rootViewController: UIViewController) -> Bool {
        // A window without a scene never displays, so fail loudly instead of
        // creating an invisible overlay. The main window is always scene-attached
        // while UI is on screen. Bail before tearing down any existing overlay.
        guard let windowScene = self.window.windowScene else {
            assertionFailure("displayOverlayingWindow requires a scene-attached main window")
            return false
        }
        removeOverlayingWindow()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        window.windowLevel = .alert
        window.isHidden = false
        window.makeKeyAndVisible()
        overlayingWindow = window
        return true
    }

    private func removeOverlayingWindow() {
        overlayingWindowReplacementHandler = nil
        guard let overlayingWindow else {
            return
        }
        overlayingWindow.isHidden = true
        self.overlayingWindow = nil
        window.makeKey()
    }
}

// MARK: - Sign-In Gate

extension WindowManager: SignInGateHost {
    var isSignInGateVisible: Bool {
        guard isShowingSignInGate, let overlayingWindow else {
            return false
        }
        return overlayingWindow.windowScene != nil && !overlayingWindow.isHidden
    }

    func showSignInGate(_ viewController: UIViewController) {
        // Take the window from other content, such as the Jetpack features overlay, and tell its owner. The handler
        // is nil while the gate is showing, because `displayOverlayingWindow` does nothing then.
        let replacementHandler = overlayingWindowReplacementHandler
        isShowingSignInGate = false
        removeOverlayingWindow()
        replacementHandler?()

        // The main window has no scene during a background launch. The coordinator shows the gate again when the
        // app UI is shown or the app enters the foreground.
        guard window.windowScene != nil, installOverlayingWindow(with: viewController) else {
            return
        }
        isShowingSignInGate = true
    }

    func dismissSignInGate() {
        guard isShowingSignInGate else {
            return
        }
        isShowingSignInGate = false
        removeOverlayingWindow()
    }
}
