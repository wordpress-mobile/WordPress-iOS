import Foundation

struct MeRoute: Route {
    let path = "/me"
    let section: DeepLinkSection? = .me
    let action: NavigationAction = MeNavigationAction.root
    let jetpackPowered: Bool = false
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

    func perform(_ values: [String: String] = [:], source: UIViewController? = nil, router: LinkRouter) {
        switch self {
        case .root:
            RootViewCoordinator.sharedPresenter.showMeScene()
        case .accountSettings:
            RootViewCoordinator.sharedPresenter.navigateToAccountSettings()
        case .notificationSettings:
            RootViewCoordinator.sharedPresenter.switchNotificationsTabToNotificationSettings()
        }
    }
}
