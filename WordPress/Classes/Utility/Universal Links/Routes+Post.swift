import Foundation

struct NewPostRoute: Route {
    let path = "/post"
    let section: DeepLinkSection? = .editor
    let action: NavigationAction = NewPostNavigationAction()
}

struct NewPostForSiteRoute: Route {
    let path = "/post/:domain"
    let section: DeepLinkSection? = .editor
    let action: NavigationAction = NewPostNavigationAction()
}

struct NewPostNavigationAction: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil, router: LinkRouter) {
        if let blog = blog(from: values) {
            WPTabBarController.sharedInstance().showPostTab(for: blog)
        } else {
            WPTabBarController.sharedInstance().showPostTab()
        }
    }
}
