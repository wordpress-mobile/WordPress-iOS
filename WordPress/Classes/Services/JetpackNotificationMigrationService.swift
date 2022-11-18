import UIKit

protocol JetpackNotificationMigrationServiceProtocol {
    func shouldDisableNotifications() -> Bool
}

/// The service is created to support disabling WordPress notifications when Jetpack app enables notifications
/// The service uses URLScheme to determine from Jetpack app if WordPress app is installed, open it, disable notifications and come back to Jetpack app
/// This is a temporary solution to avoid duplicate notifications during the migration process from WordPress to Jetpack app
/// This service and its usage can be deleted once the migration is done
final class JetpackNotificationMigrationService: JetpackNotificationMigrationServiceProtocol {
    private let notificationSettingsLoader: NotificationSettingsLoader
    private let remoteNotificationRegister: RemoteNotificationRegister
    private var notificationsEnabled: Bool = false
    private let allowDisablingWPNotifications: Bool
    private let isWordPress: Bool
    private let userDefaults = UserDefaults(suiteName: WPAppGroupName)

    static let shared = JetpackNotificationMigrationService()

    static let wordPressScheme = "wordpressnotificationmigration"
    static let jetpackScheme = "jetpacknotificationmigration"

    var wordPressNotificationsEnabled: Bool {
        get {
            guard let userDefaults = userDefaults,
                  userDefaults.value(forKey: WPNotificationsEnabledKey) != nil else {
                /// Treat this flag as enabled if it wasn't explicitly disabled
                return true
            }

            return userDefaults.bool(forKey: WPNotificationsEnabledKey) && remoteNotificationRegister.isRegisteredForRemoteNotifications
        }

        set {
            if newValue, isWordPress {
                remoteNotificationRegister.registerForRemoteNotifications()
            } else if isWordPress {
                remoteNotificationRegister.unregisterForRemoteNotifications()
            }
            userDefaults?.set(newValue, forKey: WPNotificationsEnabledKey)

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
         allowDisablingWPNotifications: Bool = FeatureFlag.allowDisablingWPNotifications.enabled,
         isWordPress: Bool = AppConfiguration.isWordPress) {
        self.notificationSettingsLoader = notificationSettingsLoader
        self.remoteNotificationRegister = remoteNotificationRegister
        self.allowDisablingWPNotifications = allowDisablingWPNotifications
        self.isWordPress = isWordPress

        notificationSettingsLoader.getNotificationAuthorizationStatus { [weak self] status in
            self?.notificationsEnabled = status == .authorized
        }
    }

    func shouldShowNotificationControl() -> Bool {
        return allowDisablingWPNotifications && isWordPress && notificationsEnabled
    }


    func shouldDisableNotifications() -> Bool {
        let shouldFilter = allowDisablingWPNotifications
            && isWordPress
            && !wordPressNotificationsEnabled

        if shouldFilter {
            cancelAllPendingWordPressLocalNotifications()
        }

        return shouldFilter
    }

    // MARK: - Only executed on Jetpack app

    func disableWordPressNotificationsFromJetpack() {
        guard allowDisablingWPNotifications, !isWordPress, let url = URL(string: "\(JetpackNotificationMigrationService.wordPressScheme)://") else {
            return
        }

        /// Open WordPress app to disable notifications
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Only executed on WordPress app

    func handleNotificationMigrationOnWordPress() -> Bool {
        guard isWordPress, let url = URL(string: "\(JetpackNotificationMigrationService.jetpackScheme)://") else {
            return false
        }

        wordPressNotificationsEnabled = false

        /// Return to Jetpack app
        if UIApplication.shared.canOpenURL(url) {
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
