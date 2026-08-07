import UIKit
import WordPressData

protocol JetpackNotificationMigrationServiceProtocol {
    func shouldPresentNotifications() -> Bool
}

/// The service was created to support disabling WordPress notifications when the Jetpack app enables notifications,
/// as a temporary solution to avoid duplicate notifications during the migration process from WordPress to Jetpack app.
///
/// The Jetpack app no longer initiates this migration: launching the WordPress app just to disable its notifications
/// visibly bounced the user between apps (CMM-2224), and the WordPress app has been disabling its own notifications
/// on every launch since the Jetpack features removal. The WordPress-side URL handler is kept so older Jetpack
/// versions that still open `wordpressnotificationmigration://` get redirected back instead of stranding the user.
final class JetpackNotificationMigrationService: JetpackNotificationMigrationServiceProtocol {
    private let remoteNotificationRegister: RemoteNotificationRegister
    private let featureFlagStore: RemoteFeatureFlagStore
    private let userDefaults: UserDefaults
    private let isWordPress: Bool

    static let shared = JetpackNotificationMigrationService()

    static let wordPressScheme = "wordpressnotificationmigration"
    static let jetpackScheme = "jetpacknotificationmigration"
    private let wordPressNotificationsToggledDefaultsKey = "wordPressNotificationsToggledDefaultsKey"

    private var jetpackMigrationPreventDuplicateNotifications: Bool {
        RemoteFeatureFlag.jetpackMigrationPreventDuplicateNotifications.enabled(using: featureFlagStore)
    }

    private lazy var notificationSettingsService: NotificationSettingsService? = {
        NotificationSettingsService(coreDataStack: ContextManager.shared)
    }()

    private lazy var bloggingRemindersScheduler: BloggingRemindersScheduler? = {
        try? BloggingRemindersScheduler(
            notificationCenter: UNUserNotificationCenter.current(),
            pushNotificationAuthorizer: InteractiveNotificationsManager.shared
        )
    }()

    var wordPressNotificationsEnabled: Bool {
        get {
            /// UIApplication.shared.isRegisteredForRemoteNotifications should be always accessed from main thread
            if Thread.isMainThread {
                return remoteNotificationRegister.isRegisteredForRemoteNotifications
            } else {
                var isRegisteredForRemoteNotifications = false
                DispatchQueue.main.sync {
                    isRegisteredForRemoteNotifications = remoteNotificationRegister.isRegisteredForRemoteNotifications
                }
                return isRegisteredForRemoteNotifications
            }
        }

        set {
            userDefaults.set(true, forKey: wordPressNotificationsToggledDefaultsKey)

            if newValue, isWordPress {
                remoteNotificationRegister.registerForRemoteNotifications()
                rescheduleLocalNotifications()
            } else if isWordPress {
                remoteNotificationRegister.unregisterForRemoteNotifications()
            }

            if isWordPress && !newValue {
                cancelAllPendingWordPressLocalNotifications()
            }
        }
    }

    init(
        remoteNotificationRegister: RemoteNotificationRegister = UIApplication.shared,
        featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore(),
        userDefaults: UserDefaults = .standard,
        isWordPress: Bool = AppConfiguration.isWordPress
    ) {
        self.remoteNotificationRegister = remoteNotificationRegister
        self.featureFlagStore = featureFlagStore
        self.userDefaults = userDefaults
        self.isWordPress = isWordPress
    }

    func shouldShowNotificationControl() -> Bool {
        jetpackMigrationPreventDuplicateNotifications && isWordPress
    }

    func shouldPresentNotifications() -> Bool {
        let notificationsDisabled = !JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled()
        let appMigrated =
            jetpackMigrationPreventDuplicateNotifications
            && isWordPress
            && userDefaults.bool(forKey: wordPressNotificationsToggledDefaultsKey)
            && !wordPressNotificationsEnabled
        let disableNotifications = notificationsDisabled || appMigrated

        if disableNotifications {
            cancelAllPendingWordPressLocalNotifications()
        }

        return !disableNotifications
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

    private func cancelAllPendingWordPressLocalNotifications(
        notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()
    ) {
        if isWordPress {
            notificationCenter.removeAllPendingNotificationRequests()
        }
    }

    func rescheduleLocalNotifications() {
        DispatchQueue.main.async { [weak self] in
            self?.rescheduleWeeklyRoundupNotifications()
            self?.rescheduleBloggingReminderNotifications()
        }
    }

    private func rescheduleWeeklyRoundupNotifications() {
        WordPressAppDelegate.shared?.backgroundTasksCoordinator.scheduleTasks { _ in }
    }

    private func rescheduleBloggingReminderNotifications() {
        notificationSettingsService?
            .getAllSettings { [weak self] settings in
                for setting in settings {
                    if let blog = setting.blog,
                        let schedule = self?.bloggingRemindersScheduler?.schedule(for: blog),
                        let time = self?.bloggingRemindersScheduler?.scheduledTime(for: blog)
                    {
                        if schedule != .none {
                            self?.bloggingRemindersScheduler?
                                .schedule(schedule, for: blog, time: time) { result in
                                    if case .success = result {
                                        BloggingRemindersFlow.setHasShownWeeklyRemindersFlow(for: blog)
                                    }
                                }
                        }
                    }
                }
            } failure: { _ in
            }
    }
}

// MARK: - Helpers

protocol RemoteNotificationRegister {
    func registerForRemoteNotifications()
    func unregisterForRemoteNotifications()
    var isRegisteredForRemoteNotifications: Bool { get }
}

extension UIApplication: RemoteNotificationRegister {}
