import Foundation
import BuildSettingsKit
import WordPressData
import WordPressShared

extension NSNotification.Name {
    static let WPAppUITypeChanged = NSNotification.Name(rawValue: "WPAppUITypeChanged")
}

class RootViewCoordinator {

    // MARK: Class Enum

    enum AppUIType {
        case normal
        case simplified
        case staticScreens

        /// The static screens phase with the `readerInWordPressApp` flag on: a live Reader tab,
        /// while Notifications and the other Jetpack features keep their posters.
        ///
        /// Notifications keeps the poster because the WordPress app shows only Reader
        /// notifications, from the bell inside Reader, and a Notifications tab would promise the
        /// account's notifications. The removal phases no longer change, so a WordPress.com
        /// account in the WordPress app always resolves to this type when the flag is on.
        case staticScreensWithReader
    }

    // MARK: Static shared variables

    static let shared = RootViewCoordinator(
        windowManager: WordPressAppDelegate.shared?.windowManager
    )
    static var sharedPresenter: RootViewPresenter {
        guard let rootViewPresenter = shared.rootViewPresenter else {
            /// Accessing RootViewPresenter before root view is presented is incorrect behavior
            /// It shows either inconsistent order of app dependency initialization
            /// or that RootViewPresenter contains actions unrelated to presented views
            DDLogWarn("RootViewPresenter is accessed before root view is presented")
            let rootViewPresenter = shared.createPresenter(shared.currentAppUIType)
            shared.rootViewPresenter = rootViewPresenter
            return rootViewPresenter
        }

        return rootViewPresenter
    }

    // MARK: Public Variables

    lazy var whatIsNewScenePresenter: ScenePresenter = {
        makeWhatIsNewPresenter()
    }()

    lazy var bloggingPromptCoordinator: BloggingPromptCoordinator = {
        makeBloggingPromptCoordinator()
    }()

    // MARK: Private instance variables

    private var rootViewPresenter: RootViewPresenter?
    private var currentAppUIType: AppUIType {
        didSet {
            updateJetpackFeaturesRemovalCoordinatorState()
        }
    }
    private var windowManager: WindowManager?
    private let app: AppBrand
    private var isReaderInWordPressAppEnabled: Bool
    private var accountChangeObserver: NSObjectProtocol?
    /// The type the current root view presenter was built for. It differs from
    /// `currentAppUIType` after an account change until `reloadUIIfNeeded` rebuilds the UI.
    private var presentedAppUIType: AppUIType?

    var isSiteCreationActive = false
    var isFullScreenOverlayBeingDisplayed = false
    // MARK: Initializer

    init(
        windowManager: WindowManager?,
        app: AppBrand = BuildSettings.current.brand,
        isReaderInWordPressAppEnabled: Bool = JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled
    ) {
        self.windowManager = windowManager
        self.currentAppUIType = Self.appUIType(app: app, isReaderInWordPressAppEnabled: isReaderInWordPressAppEnabled)
        self.app = app
        self.isReaderInWordPressAppEnabled = isReaderInWordPressAppEnabled
        updateJetpackFeaturesRemovalCoordinatorState()

        if isReaderInWordPressAppEnabled {
            observeAccountChanges()
        }
    }

    private func stopObservingAccountChanges() {
        if let accountChangeObserver {
            NotificationCenter.default.removeObserver(accountChangeObserver)
        }
        accountChangeObserver = nil
    }

    private func observeAccountChanges() {
        guard accountChangeObserver == nil else {
            return
        }
        // The UI type depends on the WordPress.com account, which can change while the app UI
        // stays in place: the iPad split view never shows My Site, whose `reloadUIIfNeeded`
        // call is the only other refresh. The default-account change is the one event every
        // sign-in and sign-out path posts; a sign-in whose site sync fails skips
        // `WPSigninDidFinishNotification`.
        accountChangeObserver = NotificationCenter.default.addObserver(
            forName: .wpAccountDefaultWordPressComAccountChanged,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            self.currentAppUIType = self.resolveAppUIType()
            self.rootViewPresenter?.appUITypeDidChange()
        }
    }

    deinit {
        if let accountChangeObserver {
            NotificationCenter.default.removeObserver(accountChangeObserver)
        }
    }

    // MARK: - Root Coordination

    func showAppUI(animated: Bool = true, completion: (() -> Void)? = nil) {
        let rootViewPresenter = createPresenter(currentAppUIType)
        windowManager?.show(rootViewPresenter.rootViewController, animated: animated, completion: completion)
        self.rootViewPresenter = rootViewPresenter

        updatePromptsIfNeeded()
    }

    func showSignInUI(completion: (() -> Void)? = nil) {
        let navigationController = LoginPrologueNavigationController(rootViewController: LoginPrologueViewController())
        windowManager?.show(navigationController, completion: completion)
        WPAnalytics.track(.openedLogin)
        self.rootViewPresenter = nil

        WordPressAppDelegate.shared?.autoSignInUITestSite()
    }

    private func createPresenter(_ appType: AppUIType) -> RootViewPresenter {
        presentedAppUIType = appType
        if app == .reader {
            return ReaderRootViewPresenter()
        }
        if UIDevice.isPad() {
            return SplitViewRootPresenter()
        }
        switch appType {
        case .normal:
            return WPTabBarController(staticScreens: false)
        case .simplified:
            return MySitesCoordinator(onBecomeActiveTab: {})
        case .staticScreens:
            return StaticScreensTabBarWrapper()
        case .staticScreensWithReader:
            // The wrapper drops Reader navigation such as `viewpost` links, so a live Reader tab
            // needs the tab bar itself.
            return WPTabBarController(staticReader: false, staticNotifications: true)
        }
    }

    // MARK: JP Features State

    /// Used to determine the expected app UI type based on the removal phase.
    private static func appUIType(app: AppBrand, isReaderInWordPressAppEnabled: Bool) -> AppUIType {
        appUIType(
            for: JetpackFeaturesRemovalCoordinator.generalPhase(app: app),
            isReaderInWordPressAppEnabled: isReaderInWordPressAppEnabled
        )
    }

    static func appUIType(
        for phase: JetpackFeaturesRemovalCoordinator.GeneralPhase,
        isReaderInWordPressAppEnabled: Bool
    ) -> AppUIType {
        switch phase {
        case .normal:
            return .normal
        case .selfHosted:
            return .simplified
        case .staticScreens:
            return isReaderInWordPressAppEnabled ? .staticScreensWithReader : .staticScreens
        }
    }

    private func resolveAppUIType() -> AppUIType {
        Self.appUIType(app: app, isReaderInWordPressAppEnabled: isReaderInWordPressAppEnabled)
    }

    private func updateJetpackFeaturesRemovalCoordinatorState() {
        JetpackFeaturesRemovalCoordinator.currentAppUIType = currentAppUIType
    }

    // MARK: Sign-In

    /// How long a sign-in waits for ExPlat and the remote feature flags before showing the app UI.
    static let signInFetchTimeout: TimeInterval = 2

    /// Prepares the app UI for an account that just signed in from the signed-out state, then
    /// calls `completion` on the main queue.
    ///
    /// In the WordPress app, `ABTest.readerInWordPressApp` and `RemoteFeatureFlag.readerInWordPressApp`
    /// decide whether Reader is live. The value read at launch is stale for someone who signs in for
    /// the first time, so without this they would see the Moved-to-Jetpack poster until the next
    /// launch whatever their group. This waits up to `timeout` for ExPlat's assignments and the
    /// account's feature flags, and then reads the value again. No app UI exists yet, so the
    /// Notifications lists can't disagree with the new value. On a timeout, whatever is stored
    /// decides: sign-out clears the assignments, so that is usually control.
    ///
    /// Other apps, and sign-ins without a WordPress.com account, call `completion` right away.
    func prepareAppUIAfterSignIn(
        timeout: TimeInterval = RootViewCoordinator.signInFetchTimeout,
        hasDotComAccount: Bool = AccountHelper.isDotcomAvailable(),
        fetch: (@escaping () -> Void) -> Void = { RootViewCoordinator.fetchAssignmentsAndFeatureFlags(completion: $0) },
        readerInWordPressAppEnabled: @escaping () -> Bool = {
            JetpackFeaturesRemovalCoordinator.readerInWordPressAppEnabled()
        },
        completion: @escaping () -> Void
    ) {
        guard app == .wordpress, hasDotComAccount else {
            completion()
            return
        }

        final class Once {
            var hasRun = false
        }
        let once = Once()
        let finish = { [weak self] in
            guard !once.hasRun else {
                return
            }
            once.hasRun = true
            self?.updateReaderInWordPressApp(isEnabled: readerInWordPressAppEnabled())
            completion()
        }
        fetch {
            DispatchQueue.main.async(execute: finish)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: finish)
    }

    /// Waits for ExPlat's assignments and the account's feature flags, and calls `completion` on
    /// the main queue once both have answered or failed.
    ///
    /// Both fetches are usually already running: the sign-in flow starts the ExPlat request
    /// (`WordPressAuthenticationManager`) and the account change starts the flag fetch
    /// (`WordPressAppDelegate`). This joins them rather than starting new ones.
    static func fetchAssignmentsAndFeatureFlags(
        startExperiments: (@escaping () -> Void) -> Void = { ABTest.start(completion: $0) },
        waitForFeatureFlags: (@escaping () -> Void) -> Void = { completion in
            guard let appDelegate = WordPressAppDelegate.shared else {
                return completion()
            }
            appDelegate.waitForSignInFeatureFlags(completion: completion)
        },
        completion: @escaping () -> Void
    ) {
        let group = DispatchGroup()
        group.enter()
        startExperiments { group.leave() }
        group.enter()
        waitForFeatureFlags { group.leave() }
        group.notify(queue: .main, execute: completion)
    }

    /// Reads whether Reader is live again after sign-out, once `ABTest.reset()` has cleared the
    /// previous account's assignments, so the next account doesn't inherit them. The sign-in UI
    /// replaces the app UI, so no Notifications list is left with the old scope.
    func readerInWordPressAppDidSignOut(
        isEnabled: Bool = JetpackFeaturesRemovalCoordinator.readerInWordPressAppEnabled()
    ) {
        updateReaderInWordPressApp(isEnabled: isEnabled)
    }

    private func updateReaderInWordPressApp(isEnabled: Bool) {
        guard isEnabled != isReaderInWordPressAppEnabled else {
            return
        }
        isReaderInWordPressAppEnabled = isEnabled
        JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled = isEnabled
        if isEnabled {
            observeAccountChanges()
        } else {
            stopObservingAccountChanges()
        }
        currentAppUIType = resolveAppUIType()
    }

    // MARK: UI Reload

    /// Reload the UI if needed after the app has already been launched.
    /// - Returns: Boolean value describing whether the UI was reloaded or not.
    @discardableResult
    func reloadUIIfNeeded(blog: Blog?) -> Bool {
        let newUIType = resolveAppUIType()
        let oldUIType = presentedAppUIType ?? currentAppUIType
        guard newUIType != oldUIType, let windowManager else {
            return false
        }
        currentAppUIType = newUIType
        displayOverlay(using: windowManager, blog: blog)
        reloadUI(using: windowManager)
        postUIReloadedNotification()
        return true
    }

    private func displayOverlay(using windowManager: WindowManager, blog: Blog?) {
        guard currentAppUIType == .simplified else {
            return
        }

        isFullScreenOverlayBeingDisplayed = true
        let viewController = BlurredEmptyViewController()

        windowManager.displayOverlayingWindow(with: viewController)

        JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(
            in: viewController,
            source: .appOpen,
            forced: true,
            fullScreen: true,
            blog: blog,
            onWillDismiss: {
                viewController.removeBlurView()
                self.isFullScreenOverlayBeingDisplayed = false
            },
            onDidDismiss: {
                windowManager.clearOverlayingWindow()
            }
        )
    }

    private func reloadUI(using windowManager: WindowManager) {
        windowManager.showUI(animated: false)
    }

    private func postUIReloadedNotification() {
        NotificationCenter.default.post(name: .WPAppUITypeChanged, object: nil)
    }
}
