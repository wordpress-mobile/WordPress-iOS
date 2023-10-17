import Foundation

struct JetpackAppStoreNotificationHandler {
    struct PushNotificationIdentifiers {
        static let key = "type"
        static let type = "jetpack_app_install"
    }

    static func handleJetpackAppInstallationNotification(_ userInfo: NSDictionary, userInteraction: Bool, completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {

        guard let type = userInfo.string(forKey: PushNotificationIdentifiers.key),
            type == PushNotificationIdentifiers.type else {
                return false
        }

        JetpackAppStoreInstallationCoordinator.shared.showJetpackAppInstallation(on: RootViewCoordinator.sharedPresenter.rootViewController)

        completionHandler?(.newData)
        return true
    }
}
