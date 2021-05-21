import Foundation

struct NotificationsRoute: Route {
    let path = "/notifications"
    let section: DeepLinkSection? = .notifications
    let action: NavigationAction = NotificationsNavigationAction()
}

struct NotificationsNavigationAction: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil, router: LinkRouter) {
        WPTabBarController.sharedInstance().showNotificationsTab()
        WPTabBarController.sharedInstance().popNotificationsTabToRoot()
    }
}
