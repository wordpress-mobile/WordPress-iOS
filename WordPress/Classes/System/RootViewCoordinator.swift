import Foundation

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
        shared.rootViewPresenter
    }

    // MARK: Public Variables

    lazy var whatIsNewScenePresenter: ScenePresenter = {
        return makeWhatIsNewPresenter()
    }()

    lazy var bloggingPromptCoordinator: BloggingPromptCoordinator = {
       return makeBloggingPromptCoordinator()
    }()

    // MARK: Private instance variables

    private(set) var rootViewPresenter: RootViewPresenter
    private var currentAppUIType: AppUIType {
        didSet {
            updateJetpackFeaturesRemovalCoordinatorState()
        }
    }
    private var featureFlagStore: RemoteFeatureFlagStore
    private var windowManager: WindowManager?

    // MARK: Initializer

    init(featureFlagStore: RemoteFeatureFlagStore,
         windowManager: WindowManager?) {
        self.featureFlagStore = featureFlagStore
        self.windowManager = windowManager
        self.currentAppUIType = Self.appUIType(featureFlagStore: featureFlagStore)
        switch self.currentAppUIType {
        case .normal:
            self.rootViewPresenter = WPTabBarController(staticScreens: false)
        case .simplified:
            let meScenePresenter = MeScenePresenter()
            self.rootViewPresenter = MySitesCoordinator(meScenePresenter: meScenePresenter, onBecomeActiveTab: {})
        case .staticScreens:
            self.rootViewPresenter = StaticScreensTabBarWrapper()
        }
        updateJetpackFeaturesRemovalCoordinatorState()
        updatePromptsIfNeeded()
    }

    // MARK: JP Features State

    /// Used to determine if the expected app UI type based on the removal phase.
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
        switch currentAppUIType {
        case .normal:
            self.rootViewPresenter = WPTabBarController(staticScreens: false)
        case .simplified:
            let meScenePresenter = MeScenePresenter()
            self.rootViewPresenter = MySitesCoordinator(meScenePresenter: meScenePresenter, onBecomeActiveTab: {})
        case .staticScreens:
            self.rootViewPresenter = StaticScreensTabBarWrapper()
        }
        windowManager.showUI(animated: false)
    }

    private func postUIReloadedNotification() {
        NotificationCenter.default.post(name: .WPAppUITypeChanged, object: nil)
    }
}
