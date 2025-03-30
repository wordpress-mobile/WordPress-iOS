import UIKit

struct NewPageRoute: Route {
    let path = "/page"
    let section: DeepLinkSection? = .editor
    let action: NavigationAction = NewPageNavigationAction()
    let jetpackPowered: Bool = false
}

struct NewPageForSiteRoute: Route {
    let path = "/page/:domain"
    let section: DeepLinkSection? = .editor
    let action: NavigationAction = NewPageNavigationAction()
    let jetpackPowered: Bool = false
}

struct NewPageNavigationAction: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil, router: LinkRouter) {
        RootViewCoordinator.sharedPresenter.showPageEditor(blog: blog(from: values))
    }
}
