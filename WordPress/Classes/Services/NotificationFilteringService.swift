import Foundation

/// The service is created to support disabling WordPress notifications when Jetpack app is installed
/// This is a temporary solution to avoid duplicate notifications during the migration process from WordPress to Jetpack app
/// This service and its usage can be deleted once the migration is done
final class NotificationFilteringService {
    private var notificationSettingsLoader: NotificationSettingsLoader
    private var notificationsEnabled: Bool = false
    private let allowDisablingWPNotifications: Bool
    private let isWordPress: Bool
    private let userDefaults = UserDefaults(suiteName: WPAppGroupName)

    var wordPressNotificationsEnabled: Bool {
        get {
            guard let userDefaults = userDefaults,
                  userDefaults.value(forKey: WPNotificationsEnabledKey) != nil else {
                /// Treat this flag as enabled if it wasn't explicitly disabled
                return true
            }

            return userDefaults.bool(forKey: WPNotificationsEnabledKey)
        }

        set {
            userDefaults?.set(newValue, forKey: WPNotificationsEnabledKey)
        }
    }

    init(notificationSettingsLoader: NotificationSettingsLoader = UNUserNotificationCenter.current(),
         allowDisablingWPNotifications: Bool = FeatureFlag.allowDisablingWPNotifications.enabled,
         isWordPress: Bool = AppConfiguration.isWordPress) {
        self.notificationSettingsLoader = notificationSettingsLoader
        self.allowDisablingWPNotifications = allowDisablingWPNotifications
        self.isWordPress = isWordPress

        notificationSettingsLoader.getNotificationAuthorizationStatus { [weak self] status in
            self?.notificationsEnabled = status == .authorized
        }
    }

    /// A temporary setting to allow controlling WordPress notifications when they are disabled after Jetpack installation
    func shouldShowNotificationControl() -> Bool {
        return allowDisablingWPNotifications && isWordPress && notificationsEnabled
    }

    /// Disable WordPress notifications when they are enabled on Jetpack
    func disableWordPressNotificationsIfNeeded() {
        if allowDisablingWPNotifications, !isWordPress {
            wordPressNotificationsEnabled = false
        }
    }

    /// Temporarily filter WordPress notifications which were disabled when Jetpack is installed
    func shouldFilterWordPressNotifications() -> Bool {
        return allowDisablingWPNotifications
            && isWordPress
            && !wordPressNotificationsEnabled
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
