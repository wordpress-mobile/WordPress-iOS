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
    private var overlayingWindow: UIWindow?

    /// A boolean to track whether we're showing the sign in flow in fullscreen mode..
    ///
    private(set) var isShowingFullscreenSignIn = false

    /// Whether a sign-in is waiting for `prepareAppUIAfterSignIn` before showing the app UI.
    private var isPreparingAppUIAfterSignIn = false

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
        guard isShowingFullscreenSignIn == true,
            AccountHelper.isLoggedIn == true,
            !isPreparingAppUIAfterSignIn
        else {
            return
        }

        isPreparingAppUIAfterSignIn = true
        prepareAppUIAfterSignIn { [weak self] in
            guard let self else { return }
            self.isPreparingAppUIAfterSignIn = false
            self.hideSignInProgress()
            // The account can be removed during the wait.
            guard AccountHelper.isLoggedIn else { return }
            self.showAppUI(for: blogToShow, completion: completion)
        }
        // The sign-in flow has already dismissed its progress indicator. Without this, the sign-in
        // screen would sit idle and accept taps, such as a second sign-in, during the wait.
        if isPreparingAppUIAfterSignIn {
            showSignInProgress()
        }
    }

    /// Waits for anything the app UI needs from the server after sign-in. Tests may override it.
    func prepareAppUIAfterSignIn(completion: @escaping Completion) {
        RootViewCoordinator.shared.prepareAppUIAfterSignIn(completion: completion)
    }

    /// The view that blocks input while a sign-in waits for `prepareAppUIAfterSignIn`.
    private(set) var signInProgressView: UIView?

    private func showSignInProgress() {
        let progressView = UIView(frame: window.bounds)
        progressView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        progressView.accessibilityViewIsModal = true

        let background = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        background.layer.cornerRadius = 16
        background.clipsToBounds = true
        background.translatesAutoresizingMaskIntoConstraints = false
        progressView.addSubview(background)

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        background.contentView.addSubview(spinner)

        NSLayoutConstraint.activate([
            background.centerXAnchor.constraint(equalTo: progressView.centerXAnchor),
            background.centerYAnchor.constraint(equalTo: progressView.centerYAnchor),
            background.widthAnchor.constraint(equalToConstant: 88),
            background.heightAnchor.constraint(equalToConstant: 88),
            spinner.centerXAnchor.constraint(equalTo: background.contentView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: background.contentView.centerYAnchor)
        ])

        // Added to the window itself so it also covers any sheet the sign-in flow left open.
        window.addSubview(progressView)
        signInProgressView = progressView
        UIAccessibility.post(notification: .screenChanged, argument: spinner)
    }

    private func hideSignInProgress() {
        signInProgressView?.removeFromSuperview()
        signInProgressView = nil
    }

    /// Shows the UI for authenticated users.
    ///
    func showAppUI(for blog: Blog? = nil, animated: Bool = true, completion: Completion? = nil) {
        isShowingFullscreenSignIn = false
        presentAppUI(for: blog, animated: animated, completion: completion)
    }

    /// Shows the initial UI for unauthenticated users.
    ///
    func showSignInUI(completion: Completion? = nil) {
        isShowingFullscreenSignIn = true
        presentSignInUI(completion: completion)
    }

    /// Puts the app UI on screen for `showAppUI`. Tests may override it.
    func presentAppUI(for blog: Blog?, animated: Bool, completion: Completion?) {
        RootViewCoordinator.shared.showAppUI(animated: animated, completion: completion)

        guard let blog else {
            return
        }

        RootViewCoordinator.sharedPresenter.showBlogDetails(for: blog)
    }

    /// Puts the sign-in UI on screen for `showSignInUI`. Tests may override it.
    func presentSignInUI(completion: Completion?) {
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
    /// - Parameter rootViewController: View controller to be used as the root view controller for the newly created window.
    ///
    func displayOverlayingWindow(with rootViewController: UIViewController) {
        // A window without a scene never displays, so fail loudly instead of
        // creating an invisible overlay. The main window is always scene-attached
        // while UI is on screen. Bail before tearing down any existing overlay.
        guard let windowScene = self.window.windowScene else {
            assertionFailure("displayOverlayingWindow requires a scene-attached main window")
            return
        }
        clearOverlayingWindow()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        window.windowLevel = .alert
        window.isHidden = false
        window.makeKeyAndVisible()
        overlayingWindow = window
    }

    /// Removes the temporary overlaying window if it exists. And makes the main window the key window again.
    ///
    func clearOverlayingWindow() {
        guard let overlayingWindow else {
            return
        }
        overlayingWindow.isHidden = true
        self.overlayingWindow = nil
        window.makeKey()
    }
}
