import Foundation

struct NotificationsRoute: Route {
    let path = "/notifications"
    let action: NavigationAction = NotificationsNavigationAction()
}

struct NotificationsNavigationAction: NavigationAction {
    func perform(_ values: [String: String]?) {
        WPTabBarController.sharedInstance().showNotificationsTab()
        WPTabBarController.sharedInstance().popNotificationsTabToRoot()
    }
}
