import Foundation

extension NSNotification.Name {
    static let WPAppUITypeChanged = NSNotification.Name(rawValue: "WPAppUITypeChanged")
}

class RootViewCoordinator {

    // MARK: Class Enum

    enum AppUIType {
        case normal
        case simplified
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
    private(set) var currentAppUIType: AppUIType
    private var featureFlagStore: RemoteFeatureFlagStore
    private var windowManager: WindowManager?

    // MARK: Initializer

    init(featureFlagStore: RemoteFeatureFlagStore,
         windowManager: WindowManager?) {
        self.featureFlagStore = featureFlagStore
        self.windowManager = windowManager
        if Self.shouldEnableJetpackFeatures(featureFlagStore: featureFlagStore) {
            self.currentAppUIType = .normal
            self.rootViewPresenter = WPTabBarController()
        }
        else {
            self.currentAppUIType = .simplified
            let meScenePresenter = MeScenePresenter()
            self.rootViewPresenter = MySitesCoordinator(meScenePresenter: meScenePresenter, onBecomeActiveTab: {})
        }
        updatePromptsIfNeeded()
    }

    // MARK: JP Features State

    /// Used to determine if the Jetpack features are enabled based on the removal phase.
    private static func shouldEnableJetpackFeatures(featureFlagStore: RemoteFeatureFlagStore) -> Bool {
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: featureFlagStore)
        switch phase {
        case .four, .newUsers, .selfHosted:
            return false
        default:
            return true
        }
    }

    // MARK: UI Reload

    /// Reload the UI if needed after the app has already been launched.
    /// - Returns: Boolean value describing whether the UI was reloaded or not.
    @discardableResult
    func reloadUIIfNeeded(blog: Blog?) -> Bool {
        let newUIType: AppUIType = Self.shouldEnableJetpackFeatures(featureFlagStore: featureFlagStore) ? .normal : .simplified
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
            self.rootViewPresenter = WPTabBarController()
        case .simplified:
            let meScenePresenter = MeScenePresenter()
            self.rootViewPresenter = MySitesCoordinator(meScenePresenter: meScenePresenter, onBecomeActiveTab: {})
        }
        windowManager.showUI(animated: false)
    }

    private func postUIReloadedNotification() {
        NotificationCenter.default.post(name: .WPAppUITypeChanged, object: nil)
    }
}
