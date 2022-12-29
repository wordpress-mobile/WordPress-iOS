import Foundation

class RootViewCoordinator {

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

    // MARK: Initializer

    init() {
        if JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() {
            self.rootViewPresenter = WPTabBarController()
        }
        else {
            let meScenePresenter = MeScenePresenter()
            self.rootViewPresenter = MySitesCoordinator(meScenePresenter: meScenePresenter, onBecomeActiveTab: {})
        }
        updatePromptsIfNeeded()
    }
}
