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
        if JetpackFeaturesRemovalCoordinator.shouldRemoveJetpackFeatures() {
            let meScenePresenter = MeScenePresenter()
            self.rootViewPresenter = MySitesCoordinator(meScenePresenter: meScenePresenter, onBecomeActiveTab: {})
        }
        else {
            self.rootViewPresenter = WPTabBarController()
        }
        updatePromptsIfNeeded()
    }
}
