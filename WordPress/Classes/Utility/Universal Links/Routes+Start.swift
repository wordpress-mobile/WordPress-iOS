import Foundation

struct StartRoute: Route, NavigationAction {
    let path = "/start"

    let section: DeepLinkSection? = .siteCreation

    var action: NavigationAction {
        return self
    }

    let jetpackPowered: Bool = true

    func perform(_ values: [String: String], source: UIViewController?, router: LinkRouter) {
        guard AccountHelper.isDotcomAvailable() else {
            return
        }

        RootViewCoordinator.sharedPresenter.mySitesCoordinator.showSiteCreation()
    }
}
