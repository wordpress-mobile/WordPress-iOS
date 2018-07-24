import Foundation

struct NewPostRoute: Route {
    let path = "/post"
    let action: NavigationAction = NewPostNavigationAction()
}

struct NewPostForSiteRoute: Route {
    let path = "/post/:domain"
    let action: NavigationAction = NewPostNavigationAction()
}

struct NewPostNavigationAction: NavigationAction {
    func perform(_ values: [String: String]? = nil) {
        if let blog = blog(from: values) {
            WPTabBarController.sharedInstance().showPostTab(for: blog)
        } else {
            WPTabBarController.sharedInstance().showPostTab()
        }
    }
}
