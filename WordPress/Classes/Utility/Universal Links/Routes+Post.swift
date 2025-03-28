import UIKit

struct NewPostRoute: Route {
    let path = "/post"
    let section: DeepLinkSection? = .editor
    let action: NavigationAction = NewPostNavigationAction()
    let jetpackPowered: Bool = false
}

struct NewPostForSiteRoute: Route {
    let path = "/post/:domain"
    let section: DeepLinkSection? = .editor
    let action: NavigationAction = NewPostNavigationAction()
    let jetpackPowered: Bool = false
}

struct NewPostNavigationAction: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil, router: LinkRouter) {
        RootViewCoordinator.sharedPresenter.showPostEditor(blog: blog(from: values))
    }
}
