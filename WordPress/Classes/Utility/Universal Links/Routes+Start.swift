import Foundation

struct StartRoute: Route, NavigationAction {
    let path = "/start"

    let section: DeepLinkSection? = .siteCreation

    var action: NavigationAction {
        return self
    }

    func perform(_ values: [String: String], source: UIViewController?, router: LinkRouter) {
        guard AccountHelper.isDotcomAvailable(),
              let coordinator = WPTabBarController.sharedInstance().mySitesCoordinator else {
            return
        }

        coordinator.showSiteCreation()
    }
}
