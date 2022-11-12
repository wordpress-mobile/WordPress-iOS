import Foundation

/// The service is created to support disabling WordPress notifications when Jetpack app is installed
/// The service uses App Groups which allows Jetpack app to change the state of notifications flag and be later accessed by WordPress app
/// This is a temporary solution to avoid duplicate notifications during the migration process from WordPress to Jetpack app
/// This service and its usage can be deleted once the migration is done
final class NotificationFilteringService {
    private var notificationSettingsLoader: NotificationSettingsLoader
    private var notificationsEnabled: Bool = false
    private let allowDisablingWPNotifications: Bool
    private let isWordPress: Bool
    private let userDefaults = UserDefaults(suiteName: WPAppGroupName)

    /// Notifications should be disabled in all the migration phases
    static var allowDisablingWPNotifications: Bool {
        FeatureFlag.jetpackFeaturesRemovalPhaseOne.enabled
        || FeatureFlag.jetpackFeaturesRemovalPhaseTwo.enabled
        || FeatureFlag.jetpackFeaturesRemovalPhaseThree.enabled
        || FeatureFlag.jetpackFeaturesRemovalPhaseFour.enabled
    }

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
         allowDisablingWPNotifications: Bool = NotificationFilteringService.allowDisablingWPNotifications,
         isWordPress: Bool = AppConfiguration.isWordPress) {
        self.notificationSettingsLoader = notificationSettingsLoader
        self.allowDisablingWPNotifications = allowDisablingWPNotifications
        self.isWordPress = isWordPress

        notificationSettingsLoader.getNotificationAuthorizationStatus { [weak self] status in
            self?.notificationsEnabled = status == .authorized
        }
    }

    func shouldShowNotificationControl() -> Bool {
        return allowDisablingWPNotifications && isWordPress && notificationsEnabled
    }

    func disableWordPressNotificationsIfNeeded() {
        if allowDisablingWPNotifications, !isWordPress {
            wordPressNotificationsEnabled = false
        }
    }

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
