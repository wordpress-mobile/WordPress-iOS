import Foundation

protocol NotificationScheduler {
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?)
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: NotificationScheduler {
}

protocol PushNotificationAuthorizer {
    func requestAuthorization(completion: @escaping (_ allowed: Bool) -> Void)
}

extension InteractiveNotificationsManager: PushNotificationAuthorizer {
}

/// Main interface for scheduling blogging reminders
///
class BloggingRemindersScheduler {

    // MARK: - Convenience Typealiases

    typealias BlogIdentifier = BloggingRemindersStore.BlogIdentifier
    typealias ScheduledReminders = BloggingRemindersStore.ScheduledReminders
    typealias ScheduledWeekday = BloggingRemindersStore.ScheduledWeekday

    // MARK: - Error Handling

    enum Error: Swift.Error {
        case cantRetrieveContainerForAppGroup(appGroupName: String)
        case needsPermissionForPushNotifications
        case noPreviousScheduleAttempt
    }

    // MARK: - Schedule Data Containers

    enum Schedule: Equatable {
        /// No reminder schedule.
        ///
        case none

        /// Weekdays reminders
        ///
        case weekdays(_ days: [Weekday])

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none):
                return true
            case (.weekdays(let leftArray), .weekdays(let rightArray)):
                return leftArray.count == rightArray.count && leftArray.sorted() == rightArray.sorted()
            default:
                return false
            }
        }
    }

    /// The raw values have been selected for convenience, so that they perfectly match Apple's
    /// index for weekday symbol methods, such as `Calendar.weekdaySymbols`.
    ///
    enum Weekday: Int, Codable, Comparable {
        case sunday = 0
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday

        /// The default reminder hour.  In the future we may want to replace this constant with a more customizable approach.
        ///
        static let defaultHour = 10

        static func < (lhs: BloggingRemindersScheduler.Weekday, rhs: BloggingRemindersScheduler.Weekday) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Scheduler State

    /// The store for persisting our schedule.
    ///
    private let store: BloggingRemindersStore

    /// The notification scheduler
    ///
    private let notificationScheduler: NotificationScheduler

    /// Push notifications authorizer
    ///
    private let pushNotificationAuthorizer: PushNotificationAuthorizer

    /// Active schedule.
    ///
    func schedule(for blog: Blog) -> Schedule {
        switch scheduledReminders(for: blog) {
        case .none:
            return .none
        case .weekdays(let days):
            return .weekdays(days.map({ $0.weekday }))
        }
    }

    // MARK: - Default Store

    private static func defaultStore() throws -> BloggingRemindersStore {
        let url = try defaultDataFileURL()
        return try BloggingRemindersStore(dataFileURL: url)
    }

    private static var defaultDataFileName = "BloggingReminders.plist"

    private static func defaultDataFileURL() throws -> URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WPAppGroupName) else {
            throw Error.cantRetrieveContainerForAppGroup(appGroupName: WPAppGroupName)
        }

        return url.appendingPathComponent(defaultDataFileName)
    }

    // MARK: - Initializers

    /// Default initializer.  Allows overriding the blogging reminders store and the notification center for testing purposes.
    ///
    ///  - Parameters:
    ///     - store: The `BloggingRemindersStore` to use for persisting the reminders schedule.
    ///     - notificationCenter: The `NotificationScheduler` to use for the notification requests.
    ///     - pushNotificationAuthorizer: The `PushNotificationAuthorizer` to use for push notification authorization.
    ///
    init(
        store: BloggingRemindersStore,
        notificationCenter: NotificationScheduler = UNUserNotificationCenter.current(),
        pushNotificationAuthorizer: PushNotificationAuthorizer = InteractiveNotificationsManager.shared) {

        self.store = store
        self.notificationScheduler = notificationCenter
        self.pushNotificationAuthorizer = pushNotificationAuthorizer
    }

    /// Default initializer.  Allows overriding the blogging reminders store and the notification center for testing purposes.
    ///
    ///  - Parameters:
    ///     - blogIdentifier, the blog identifier.  This is necessary since we support blogging reminders for multiple blogs.
    ///     - notificationCenter: The `NotificationScheduler` to use for the notification requests.
    ///     - pushNotificationAuthorizer: The `PushNotificationAuthorizer` to use for push notification authorization.
    ///
    init(
        notificationCenter: NotificationScheduler = UNUserNotificationCenter.current(),
        pushNotificationAuthorizer: PushNotificationAuthorizer = InteractiveNotificationsManager.shared) throws {

        self.store = try Self.defaultStore()
        self.notificationScheduler = notificationCenter
        self.pushNotificationAuthorizer = pushNotificationAuthorizer
    }

    // MARK: - Scheduling

    /// Main method for scheduling blogging reminder notifications.  This method will take care of scheduling the local notifications and
    /// persisting the user-defined reminder schedule.
    ///
    /// - Parameters:
    ///     - schedule: the blogging reminders schedule.
    ///
    func schedule(_ schedule: Schedule, for blog: Blog, completion: @escaping (Result<Void, Swift.Error>) -> ()) {
        guard schedule != .none else {
            // If there's no schedule, then we don't need to request authorization
            pushAuthorizationReceived(blog: blog, schedule: schedule, completion: completion)
            return
        }

        pushNotificationAuthorizer.requestAuthorization { [weak self] allowed in
            guard let self = self else {
                return
            }

            guard allowed else {
                completion(.failure(Error.needsPermissionForPushNotifications))
                return
            }

            self.pushAuthorizationReceived(blog: blog, schedule: schedule, completion: completion)
        }
    }

    /// You should not be calling this method directly.  Instead, make sure to use `schedule(_:completion:)`.
    ///
    private func pushAuthorizationReceived(blog: Blog, schedule: Schedule, completion: (Result<Void, Swift.Error>) -> ()) {
        unschedule(scheduledReminders(for: blog))

        let scheduledReminders: BloggingRemindersStore.ScheduledReminders

        switch schedule {
        case .none:
            scheduledReminders = .none
        case .weekdays(let days):
            scheduledReminders = .weekdays(scheduled(days))
        }

        do {
            try store.save(scheduledReminders: scheduledReminders, for: blog.objectID.uriRepresentation())
        } catch {
            completion(.failure(error))
            return
        }

        completion(.success(()))
    }

    /// Schedules a notifications for the passed days, and returns another array with the days and their
    /// associated notification IDs.
    ///
    /// - Parameters:
    ///     - weekdays: the weekdays to schedule notifications for.
    ///
    /// - Returns: the weekdays with the associated notification IDs.
    ///
    private func scheduled(_ weekdays: [Weekday]) -> [ScheduledWeekday] {
        weekdays.map { scheduled($0) }
    }

    /// Schedules a notification for the passed day, and returns the day with the associated notification ID.
    ///
    /// - Parameters:
    ///     - weekday: the weekday to schedule a notification for.
    ///
    /// - Returns: the weekday with the associated notification ID.
    ///
    private func scheduled(_ weekday: Weekday) -> ScheduledWeekday {
        let notificationID = scheduleNotification(for: weekday)
        return ScheduledWeekday(weekday: weekday, notificationID: notificationID)
    }

    /// Schedules a notification for the specified weekday.
    ///
    private func scheduleNotification(for weekday: Weekday) -> String {
        let content = UNMutableNotificationContent()
        content.title = "Blogging Reminder"
        content.body = "It's time to post!"

        var dateComponents = DateComponents()
        let calendar = Calendar.current
        dateComponents.calendar = calendar

        // `DateComponent`'s weekday uses a 1-based index.
        dateComponents.weekday = weekday.rawValue + 1
        dateComponents.hour = Weekday.defaultHour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)

        notificationScheduler.add(request) { (error) in
            if let error = error {
                DDLogError(error.localizedDescription)
            }
        }

        return uuidString
    }

    // MARK: - Unscheduling
    func unschedule(for blogs: [Blog]) {
        for blog in blogs {
            unschedule(for: blog)
        }
    }

    func unschedule(for blog: Blog) {
        schedule(.none, for: blog, completion: { _ in })
    }

    /// Unschedules all notifications for the passed schedule.
    ///
    private func unschedule(_ schedule: ScheduledReminders) {
        switch schedule {
        case .none:
            return
        case .weekdays(let days):
            unschedule(days)
        }
    }

    /// Unschedules all notiication for the specified days.
    ///
    private func unschedule(_ days: [ScheduledWeekday]) {
        let notificationIDs = days.map { $0.notificationID }

        notificationScheduler.removePendingNotificationRequests(withIdentifiers: notificationIDs)
    }

    // MARK: - Scheduled Reminders

    private func scheduledReminders(for blog: Blog) -> ScheduledReminders {
        store.scheduledReminders(for: blog.objectID.uriRepresentation())
    }
}
