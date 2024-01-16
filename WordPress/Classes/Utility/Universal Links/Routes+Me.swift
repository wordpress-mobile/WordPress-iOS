import Foundation

struct MeRoute: Route {
    let path = "/me"
    let section: DeepLinkSection? = .me
    let action: NavigationAction = MeNavigationAction.root
    let jetpackPowered: Bool = false
}

struct MeAllDomainsRoute: Route {
    let path = "/domains/manage"
    let section: DeepLinkSection? = .me
    let action: NavigationAction = MeNavigationAction.allDomains
    let jetpackPowered: Bool = true
}

struct MeAccountSettingsRoute: Route {
    let path = "/me/account"
    let section: DeepLinkSection? = .me
    let action: NavigationAction = MeNavigationAction.accountSettings
    let jetpackPowered: Bool = false
}

struct MeNotificationSettingsRoute: Route {
    let path = "/me/notifications"
    let section: DeepLinkSection? = .me
    let action: NavigationAction = MeNavigationAction.notificationSettings
    let jetpackPowered: Bool = true
}

enum MeNavigationAction: NavigationAction {
    case root
    case accountSettings
    case notificationSettings
    case allDomains

    func perform(_ values: [String: String] = [:], source: UIViewController? = nil, router: LinkRouter) {
        switch self {
        case .root:
            RootViewCoordinator.sharedPresenter.showMeScreen()
        case .accountSettings:
            RootViewCoordinator.sharedPresenter.navigateToAccountSettings()
        case .notificationSettings:
            RootViewCoordinator.sharedPresenter.switchNotificationsTabToNotificationSettings()
        case .allDomains:
            RootViewCoordinator.sharedPresenter.navigateToAllDomains()
        }
    }
}
