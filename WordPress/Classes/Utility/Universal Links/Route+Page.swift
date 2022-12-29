import Foundation

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
        if let blog = blog(from: values) {
            RootViewCoordinator.sharedPresenter.showPageEditor(forBlog: blog)
        } else {
            RootViewCoordinator.sharedPresenter.showPageEditor()
        }
    }
}
