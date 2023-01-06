import UIKit

protocol JetpackNotificationMigrationServiceProtocol {
    func shouldPresentNotifications() -> Bool
}

/// The service is created to support disabling WordPress notifications when Jetpack app enables notifications
/// The service uses URLScheme to determine from Jetpack app if WordPress app is installed, open it, disable notifications and come back to Jetpack app
/// This is a temporary solution to avoid duplicate notifications during the migration process from WordPress to Jetpack app
/// This service and its usage can be deleted once the migration is done
final class JetpackNotificationMigrationService: JetpackNotificationMigrationServiceProtocol {
    private let remoteNotificationRegister: RemoteNotificationRegister
    private let featureFlagStore: RemoteFeatureFlagStore
    private let userDefaults: UserDefaults
    private let isWordPress: Bool

    static let shared = JetpackNotificationMigrationService()

    static let wordPressScheme = "wordpressnotificationmigration"
    static let jetpackScheme = "jetpacknotificationmigration"
    private let wordPressNotificationsToggledDefaultsKey = "wordPressNotificationsToggledDefaultsKey"
    private let jetpackNotificationMigrationDefaultsKey = "jetpackNotificationMigrationDefaultsKey"

    private var jetpackMigrationPreventDuplicateNotifications: Bool {
        return featureFlagStore.value(for: FeatureFlag.jetpackMigrationPreventDuplicateNotifications)
    }

    private var notificationSettingsService: NotificationSettingsService?
    private var bloggingRemindersScheduler: BloggingRemindersScheduler?

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

    /// Migration is supported if WordPress is compatible with the notification migration URLScheme
    var isMigrationSupported: Bool {
        guard let url = URL(string: "\(JetpackNotificationMigrationService.wordPressScheme)://") else {
            return false
        }

        return UIApplication.shared.canOpenURL(url) && jetpackMigrationPreventDuplicateNotifications
    }

    /// disableWordPressNotificationsFromJetpack may get triggered multiple times from Jetpack app but it only needs to be executed the first time
    private var isMigrationDone: Bool {
        get {
            return userDefaults.bool(forKey: jetpackNotificationMigrationDefaultsKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: jetpackNotificationMigrationDefaultsKey)
        }
    }

    init(remoteNotificationRegister: RemoteNotificationRegister = UIApplication.shared,
         featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore(),
         userDefaults: UserDefaults = .standard,
         isWordPress: Bool = AppConfiguration.isWordPress) {
        self.remoteNotificationRegister = remoteNotificationRegister
        self.featureFlagStore = featureFlagStore
        self.userDefaults = userDefaults
        self.isWordPress = isWordPress
    }

    func shouldShowNotificationControl() -> Bool {
        return jetpackMigrationPreventDuplicateNotifications && isWordPress
    }

    func shouldPresentNotifications() -> Bool {
        let notificationsDisabled = !JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled()
        let appMigrated = jetpackMigrationPreventDuplicateNotifications
            && isWordPress
            && userDefaults.bool(forKey: wordPressNotificationsToggledDefaultsKey)
            && !wordPressNotificationsEnabled
        let disableNotifications = notificationsDisabled || appMigrated

        if disableNotifications {
            cancelAllPendingWordPressLocalNotifications()
        }

        return !disableNotifications
    }

    // MARK: - Only executed on Jetpack app

    func disableWordPressNotificationsFromJetpack() {
        guard !isMigrationDone, jetpackMigrationPreventDuplicateNotifications, !isWordPress else {
            return
        }

        let wordPressUrl: URL? = {
            var components = URLComponents()
            components.scheme = JetpackNotificationMigrationService.wordPressScheme
            return components.url
        }()

        /// Open WordPress app to disable notifications
        if let url = wordPressUrl, UIApplication.shared.canOpenURL(url) {
            isMigrationDone = true
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
        bloggingRemindersScheduler = try? BloggingRemindersScheduler(
            notificationCenter: UNUserNotificationCenter.current(),
            pushNotificationAuthorizer: InteractiveNotificationsManager.shared
        )
        notificationSettingsService = NotificationSettingsService(coreDataStack: ContextManager.sharedInstance())

        notificationSettingsService?.getAllSettings { [weak self] settings in
            let group = DispatchGroup()

            for setting in settings {
                if let blog = setting.blog,
                   let schedule = self?.bloggingRemindersScheduler?.schedule(for: blog),
                   let time = self?.bloggingRemindersScheduler?.scheduledTime(for: blog) {
                    if schedule != .none {
                        group.enter()
                        self?.bloggingRemindersScheduler?.schedule(schedule, for: blog, time: time) { result in
                            if case .success = result {
                                BloggingRemindersFlow.setHasShownWeeklyRemindersFlow(for: blog)
                            }

                            group.leave()
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self?.bloggingRemindersScheduler = nil
                self?.notificationSettingsService = nil
            }

        } failure: { _ in }
    }
}

// MARK: - Helpers

protocol RemoteNotificationRegister {
    func registerForRemoteNotifications()
    func unregisterForRemoteNotifications()
    var isRegisteredForRemoteNotifications: Bool { get }
}

extension UIApplication: RemoteNotificationRegister {}
