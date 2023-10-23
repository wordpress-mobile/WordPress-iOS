import Foundation
import WordPressAuthenticator

extension NSNotification.Name {
    static let WPAppUITypeChanged = NSNotification.Name(rawValue: "WPAppUITypeChanged")
}

class RootViewCoordinator {

    // MARK: Class Enum

    enum AppUIType {
        case normal
        case simplified
        case staticScreens
    }

    // MARK: Static shared variables

    static let shared = RootViewCoordinator(featureFlagStore: RemoteFeatureFlagStore(),
                                            windowManager: WordPressAppDelegate.shared?.windowManager)
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
        return makeWhatIsNewPresenter()
    }()

    lazy var bloggingPromptCoordinator: BloggingPromptCoordinator = {
       return makeBloggingPromptCoordinator()
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
    private let wordPressAuthenticator: WordPressAuthenticatorProtocol.Type

    // MARK: Initializer

    init(featureFlagStore: RemoteFeatureFlagStore,
         windowManager: WindowManager?,
         wordPressAuthenticator: WordPressAuthenticatorProtocol.Type = WordPressAuthenticator.self) {
        self.featureFlagStore = featureFlagStore
        self.windowManager = windowManager
        self.currentAppUIType = Self.appUIType(featureFlagStore: featureFlagStore)
        self.wordPressAuthenticator = wordPressAuthenticator
        updateJetpackFeaturesRemovalCoordinatorState()
    }

    // MARK: - Root Coordination

    func showAppUI(animated: Bool = true, completion: (() -> Void)? = nil) {
        let rootViewPresenter = createPresenter(currentAppUIType)
        windowManager?.show(rootViewPresenter.rootViewController, animated: animated, completion: completion)
        self.rootViewPresenter = rootViewPresenter

        updatePromptsIfNeeded()
    }

    func showSignInUI(completion: (() -> Void)? = nil) {
        guard let loginViewController = wordPressAuthenticator.loginUI() else {
            fatalError("No login UI to show to the user.  There's no way to gracefully handle this error.")
        }

        windowManager?.show(loginViewController, completion: completion)
        wordPressAuthenticator.track(.openedLogin)
        self.rootViewPresenter = nil
    }

    func showPostSignUpTabForNoSites() {
        let appUIType = Self.appUIType(featureFlagStore: featureFlagStore)
        switch appUIType {
        case .normal:
            rootViewPresenter?.showReaderTab()
        case .simplified:
            fallthrough
        case .staticScreens:
            rootViewPresenter?.showMySitesTab()
        }
    }

    private func createPresenter(_ appType: AppUIType) -> RootViewPresenter {
        switch appType {
        case .normal:
            return WPTabBarController(staticScreens: false)
        case .simplified:
            let meScenePresenter = MeScenePresenter()
            return MySitesCoordinator(meScenePresenter: meScenePresenter, onBecomeActiveTab: {})
        case .staticScreens:
            return StaticScreensTabBarWrapper()
        }
    }

    // MARK: JP Features State

    /// Used to determine the expected app UI type based on the removal phase.
    private static func appUIType(featureFlagStore: RemoteFeatureFlagStore) -> AppUIType {
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: featureFlagStore)
        switch phase {
        case .four, .newUsers, .selfHosted:
            return .simplified
        case .staticScreens:
            return .staticScreens
        default:
            return .normal
        }
    }

    private func updateJetpackFeaturesRemovalCoordinatorState() {
        JetpackFeaturesRemovalCoordinator.currentAppUIType = currentAppUIType
    }

    // MARK: UI Reload

    /// Reload the UI if needed after the app has already been launched.
    /// - Returns: Boolean value describing whether the UI was reloaded or not.
    @discardableResult
    func reloadUIIfNeeded(blog: Blog?) -> Bool {
        let newUIType: AppUIType = Self.appUIType(featureFlagStore: featureFlagStore)
        let oldUIType = currentAppUIType
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

        let viewController = BlurredEmptyViewController()

        windowManager.displayOverlayingWindow(with: viewController)

        JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(in: viewController,
                                                                 source: .appOpen,
                                                                 forced: true,
                                                                 fullScreen: true,
                                                                 blog: blog,
                                                                 onWillDismiss: {
            viewController.removeBlurView()
        }, onDidDismiss: {
            windowManager.clearOverlayingWindow()
        })
    }

    private func reloadUI(using windowManager: WindowManager) {
        windowManager.showUI(animated: false)
    }

    private func postUIReloadedNotification() {
        NotificationCenter.default.post(name: .WPAppUITypeChanged, object: nil)
    }
}
