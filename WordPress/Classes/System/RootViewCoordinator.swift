import Foundation

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
        if JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() {
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

    func reloadUIIfNeeded() {
        let newUIType: AppUIType = JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() ? .normal : .simplified
        let oldUIType = currentAppUIType
        guard newUIType != oldUIType, let windowManager = WordPressAppDelegate.shared?.windowManager else {
            return
        }
        currentAppUIType = newUIType
        displayOverlay(using: windowManager)
        reloadUI(using: windowManager)
    }

    private func displayOverlay(using windowManager: WindowManager) {
        guard currentAppUIType == .simplified else {
            return
        }

        let viewController = BlurredEmptyViewController()

        windowManager.displayOverlayingWindow(with: viewController)

        JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(in: viewController, source: .appOpen, forced: true, fullScreen: true) {
            viewController.removeBlurView()
        } onDidDismiss: {
            windowManager.clearOverlayingWindow()
        }
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
}
