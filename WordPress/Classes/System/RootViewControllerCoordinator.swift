import Foundation

class RootViewControllerCoordinator {

    // MARK: Static shared variables

    static let shared = RootViewControllerCoordinator()
    static var sharedPresenter: RootViewPresenter {
        shared.rootViewPresenter
    }

    // MARK: Private instance variables

    private var rootViewPresenter: RootViewPresenter

    // MARK: Initializer

    init() {
        if JetpackFeaturesRemovalCoordinator.shouldRemoveJetpackFeatures() {
            let meScenePresenter = MeScenePresenter()
            self.rootViewPresenter = MySitesCoordinator(meScenePresenter: meScenePresenter, onBecomeActiveTab: {})
        }
        else {
            self.rootViewPresenter = WPTabBarController.sharedInstance() // TODO: Remove shared instance and create an instance here
        }
    }
}
