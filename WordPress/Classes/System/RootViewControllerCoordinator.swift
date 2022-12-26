import Foundation

class RootViewControllerCoordinator {

    // MARK: Class Enum

    enum AppUIType {
        case normal
        case simplified
    }

    // MARK: Static shared variables

    static let shared = RootViewControllerCoordinator()
    static var sharedPresenter: RootViewPresenter {
        shared.rootViewPresenter
    }

    // MARK: Private instance variables

    private var currentAppUIType: AppUIType
    private var rootViewPresenter: RootViewPresenter

    // MARK: Initializer

    init() {
        if JetpackFeaturesRemovalCoordinator.shouldRemoveJetpackFeatures() {
            self.currentAppUIType = .simplified
            let meScenePresenter = MeScenePresenter()
            self.rootViewPresenter = MySitesCoordinator(meScenePresenter: meScenePresenter, onBecomeActiveTab: {})
        }
        else {
            self.currentAppUIType = .normal
            self.rootViewPresenter = WPTabBarController.sharedInstance() // TODO: Remove shared instance and create an instance here
        }
    }
}
