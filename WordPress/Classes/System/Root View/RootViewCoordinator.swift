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
        /// The WordPress app with a WordPress.com account and the
        /// `readerAndNotificationsInWordPressApp` flag on: live Reader and Notifications tabs,
        /// while the other Jetpack features stay disabled as in `staticScreens`.
        case readerTabs
    }

    // MARK: Static shared variables

    static let shared = RootViewCoordinator(
        featureFlagStore: RemoteFeatureFlagStore(),
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
    private var featureFlagStore: RemoteFeatureFlagStore
    private var windowManager: WindowManager?
    private let app: AppBrand
    private let isReaderAndNotificationsEnabled: Bool
    private var accountChangeObserver: NSObjectProtocol?
    /// The type the current root view presenter was built for. It differs from
    /// `currentAppUIType` after an account change until `reloadUIIfNeeded` rebuilds the UI.
    private var presentedAppUIType: AppUIType?

    var isSiteCreationActive = false
    var isFullScreenOverlayBeingDisplayed = false
    // MARK: Initializer

    init(
        featureFlagStore: RemoteFeatureFlagStore,
        windowManager: WindowManager?,
        app: AppBrand = BuildSettings.current.brand,
        isReaderAndNotificationsEnabled: Bool = FeatureFlag.readerAndNotificationsInWordPressApp.enabled
    ) {
        self.featureFlagStore = featureFlagStore
        self.windowManager = windowManager
        self.currentAppUIType = Self.appUIType(
            featureFlagStore: featureFlagStore,
            app: app,
            isReaderAndNotificationsEnabled: isReaderAndNotificationsEnabled
        )
        self.app = app
        self.isReaderAndNotificationsEnabled = isReaderAndNotificationsEnabled
        updateJetpackFeaturesRemovalCoordinatorState()

        if isReaderAndNotificationsEnabled {
            // Without this, the type keeps its launch value until My Site appears and calls
            // `reloadUIIfNeeded`. Checks that run before that read the stale type: the post-login
            // notifications prompt, push registration, and the iPad sidebar, which never shows My Site.
            accountChangeObserver = NotificationCenter.default.addObserver(
                forName: .wpAccountDefaultWordPressComAccountChanged,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                guard let self else { return }
                self.currentAppUIType = self.resolveAppUIType()
            }
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
        case .normal, .readerTabs:
            return WPTabBarController(staticScreens: false)
        case .simplified:
            return MySitesCoordinator(onBecomeActiveTab: {})
        case .staticScreens:
            return StaticScreensTabBarWrapper()
        }
    }

    // MARK: JP Features State

    /// Used to determine the expected app UI type based on the removal phase.
    private static func appUIType(
        featureFlagStore: RemoteFeatureFlagStore,
        app: AppBrand,
        isReaderAndNotificationsEnabled: Bool
    ) -> AppUIType {
        // The flag wins over every removal phase so that a remote phase change can't take
        // Reader and Notifications away from WordPress.com accounts.
        if app == .wordpress && isReaderAndNotificationsEnabled && !AccountHelper.noWordPressDotComAccount {
            return .readerTabs
        }
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: featureFlagStore, app: app)
        switch phase {
        case .four, .newUsers, .selfHosted:
            return .simplified
        case .staticScreens:
            return .staticScreens
        default:
            return .normal
        }
    }

    private func resolveAppUIType() -> AppUIType {
        Self.appUIType(
            featureFlagStore: featureFlagStore,
            app: app,
            isReaderAndNotificationsEnabled: isReaderAndNotificationsEnabled
        )
    }

    private func updateJetpackFeaturesRemovalCoordinatorState() {
        JetpackFeaturesRemovalCoordinator.currentAppUIType = currentAppUIType
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
