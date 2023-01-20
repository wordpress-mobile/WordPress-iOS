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

    static let shared = RootViewCoordinator()
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
    private var currentAppUIType: AppUIType

    // MARK: Initializer

    init() {
        if Self.shouldEnableJetpackFeatures() {
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

    /// Used to determine if the Jetpack features are enabled based on the current app UI type.
    /// Using this ensures features are not removed before reloading the UI.
    /// - Returns: `true` if UI type if normal, and `false` if UI type is simplified.
    func jetpackFeaturesEnabled() -> Bool {
        return currentAppUIType == .normal
    }

    private static func shouldEnableJetpackFeatures() -> Bool {
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase()
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
    func reloadUIIfNeeded(blog: Blog?) -> Bool {
        let newUIType: AppUIType = Self.shouldEnableJetpackFeatures() ? .normal : .simplified
        let oldUIType = currentAppUIType
        guard newUIType != oldUIType, let windowManager = WordPressAppDelegate.shared?.windowManager else {
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
