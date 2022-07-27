import Foundation

struct MeRoute: Route {
    let path = "/me"
    let section: DeepLinkSection? = .me
    let action: NavigationAction = MeNavigationAction.root
}

struct MeAccountSettingsRoute: Route {
    let path = "/me/account"
    let section: DeepLinkSection? = .me
    let action: NavigationAction = MeNavigationAction.accountSettings
}

struct MeNotificationSettingsRoute: Route {
    let path = "/me/notifications"
    let section: DeepLinkSection? = .me
    let action: NavigationAction = MeNavigationAction.notificationSettings
}

enum MeNavigationAction: NavigationAction {
    case root
    case accountSettings
    case notificationSettings

    func perform(_ values: [String: String] = [:], source: UIViewController? = nil, router: LinkRouter) {
        switch self {
        case .root:
            WPTabBarController.sharedInstance().showMeScene()
        case .accountSettings:
            WPTabBarController.sharedInstance().navigateToAccountSettings()
        case .notificationSettings:
            WPTabBarController.sharedInstance().switchNotificationsTabToNotificationSettings()
        }
    }
}
