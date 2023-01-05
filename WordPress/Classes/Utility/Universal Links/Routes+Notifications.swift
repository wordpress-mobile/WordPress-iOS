import Foundation

struct NotificationsRoute: Route {
    let path = "/notifications"
    let section: DeepLinkSection? = .notifications
    let action: NavigationAction = NotificationsNavigationAction()
    let jetpackPowered: Bool = true
}

struct NotificationsNavigationAction: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil, router: LinkRouter) {
        RootViewCoordinator.sharedPresenter.showNotificationsTab()
        RootViewCoordinator.sharedPresenter.popNotificationsTabToRoot()
    }
}
