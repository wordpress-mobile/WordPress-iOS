import Foundation

struct NewPostRoute: Route {
    let path = "/post"
    let action: NavigationAction = NewPostNavigationAction()
}

struct NewPostForSiteRoute: Route {
    let path = "/post/:\(NewPostRoutePlaceholder.site.rawValue)"
    let action: NavigationAction = NewPostNavigationAction()
}

struct NewPostNavigationAction: NavigationAction {
    func perform(_ values: [String: String]? = nil) {
        if let site = values?[NewPostRoutePlaceholder.site.rawValue] {
            let context = ContextManager.sharedInstance().mainContext
            let service = BlogService(managedObjectContext: context)
            let blog = service.blog(byHostname: site)
            WPTabBarController.sharedInstance().showPostTab(for: blog)
        } else {
            WPTabBarController.sharedInstance().showPostTab()
        }
    }
}

private enum NewPostRoutePlaceholder: String {
    case site
}
