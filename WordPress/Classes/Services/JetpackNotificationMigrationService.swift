import UIKit

protocol JetpackNotificationMigrationServiceProtocol {
    func shouldPresentNotifications() -> Bool
}

/// The service is created to support disabling WordPress notifications when Jetpack app enables notifications
/// The service uses URLScheme to determine from Jetpack app if WordPress app is installed, open it, disable notifications and come back to Jetpack app
/// This is a temporary solution to avoid duplicate notifications during the migration process from WordPress to Jetpack app
/// This service and its usage can be deleted once the migration is done
final class JetpackNotificationMigrationService: JetpackNotificationMigrationServiceProtocol {
    private let notificationSettingsLoader: NotificationSettingsLoader
    private let remoteNotificationRegister: RemoteNotificationRegister
    private let featureFlagStore: RemoteFeatureFlagStore
    private var notificationsEnabled: Bool = false
    private let isWordPress: Bool

    static let shared = JetpackNotificationMigrationService()

    static let wordPressScheme = "wordpressnotificationmigration"
    static let jetpackScheme = "jetpacknotificationmigration"

    private var jetpackMigrationPreventDuplicateNotifications: Bool {
        return featureFlagStore.value(for: FeatureFlag.jetpackMigrationPreventDuplicateNotifications)
    }

    var wordPressNotificationsEnabled: Bool {
        get {
            return remoteNotificationRegister.isRegisteredForRemoteNotifications
        }

        set {
            if newValue, isWordPress {
                remoteNotificationRegister.registerForRemoteNotifications()
            } else if isWordPress {
                remoteNotificationRegister.unregisterForRemoteNotifications()
            }

            if isWordPress && !newValue {
                cancelAllPendingWordPressLocalNotifications()
            }
        }
    }

    /// Migration is supported if WordPress is compatible with the notification migration URLScheme
    var isMigrationSupported: Bool {
        guard let url = URL(string: "\(JetpackNotificationMigrationService.wordPressScheme)://") else {
            return false
        }

        return UIApplication.shared.canOpenURL(url)
    }

    init(notificationSettingsLoader: NotificationSettingsLoader = UNUserNotificationCenter.current(),
         remoteNotificationRegister: RemoteNotificationRegister = UIApplication.shared,
         featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore(),
         isWordPress: Bool = AppConfiguration.isWordPress) {
        self.notificationSettingsLoader = notificationSettingsLoader
        self.remoteNotificationRegister = remoteNotificationRegister
        self.featureFlagStore = featureFlagStore
        self.isWordPress = isWordPress

        notificationSettingsLoader.getNotificationAuthorizationStatus { [weak self] status in
            self?.notificationsEnabled = status == .authorized
        }
    }

    func shouldShowNotificationControl() -> Bool {
        return jetpackMigrationPreventDuplicateNotifications && isWordPress && notificationsEnabled
    }


    func shouldPresentNotifications() -> Bool {
        let disableNotifications = jetpackMigrationPreventDuplicateNotifications
            && isWordPress
            && !wordPressNotificationsEnabled

        if disableNotifications {
            cancelAllPendingWordPressLocalNotifications()
        }

        return !disableNotifications
    }

    // MARK: - Only executed on Jetpack app

    func disableWordPressNotificationsFromJetpack() {
        guard jetpackMigrationPreventDuplicateNotifications, !isWordPress else {
            return
        }

        let wordPressUrl: URL? = {
            var components = URLComponents()
            components.scheme = JetpackNotificationMigrationService.wordPressScheme
            return components.url
        }()

        /// Open WordPress app to disable notifications
        if let url = wordPressUrl, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Only executed on WordPress app

    func handleNotificationMigrationOnWordPress() -> Bool {
        guard isWordPress else {
            return false
        }

        wordPressNotificationsEnabled = false

        let jetpackUrl: URL? = {
            var components = URLComponents()
            components.scheme = JetpackNotificationMigrationService.jetpackScheme
            return components.url
        }()

        /// Return to Jetpack app
        if let url = jetpackUrl, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }

        return true
    }

    // MARK: - Local notifications

    private func cancelAllPendingWordPressLocalNotifications(notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()) {
        if isWordPress {
            notificationCenter.removeAllPendingNotificationRequests()
        }
    }
}

// MARK: - Helpers

protocol NotificationSettingsLoader: AnyObject {
    func getNotificationAuthorizationStatus(completionHandler: @escaping (UNAuthorizationStatus) -> Void)
}

extension UNUserNotificationCenter: NotificationSettingsLoader {
    func getNotificationAuthorizationStatus(completionHandler: @escaping (UNAuthorizationStatus) -> Void) {
        getNotificationSettings { settings in
            completionHandler(settings.authorizationStatus)
        }
    }
}

protocol RemoteNotificationRegister {
    func registerForRemoteNotifications()
    func unregisterForRemoteNotifications()
    var isRegisteredForRemoteNotifications: Bool { get }
}

extension UIApplication: RemoteNotificationRegister {}
