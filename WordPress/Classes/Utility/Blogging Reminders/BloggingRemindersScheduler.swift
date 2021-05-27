import Foundation

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
    }

    // MARK: - Schedule Data Containers

    enum Schedule {
        /// No reminder schedule.
        ///
        case none

        /// Weekdays reminders
        ///
        case weekdays(_ days: [Weekday])
    }

    enum Weekday: Int, Codable {
        case sunday = 1 // Keep this at 1 to match Apple's `DateComponents`' weekday number.
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday

        /// The default reminder hour.  In the future we may want to replace this constant with a more customizable approach.
        ///
        static let defaultHour = 10
    }

    // MARK: - Scheduler State

    /// The identifier for the blog this scheduler is working on.
    ///
    let blogIdentifier: URL

    /// The store for persisting our schedule.
    ///
    private let store: BloggingRemindersStore

    /// The notification center
    ///
    private let notificationCenter: UNUserNotificationCenter

    private var scheduledReminders: ScheduledReminders {
        store.scheduledReminders(for: blogIdentifier)
    }

    /// Active schedule.
    ///
    func schedule() -> Schedule {
        switch scheduledReminders {
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
    ///     - blogIdentifier, the blog identifier.  This is necessary since we support blogging reminders for multiple blogs.
    ///     - store: The `BloggingRemindersStore` to use for persisting the reminders schedule.
    ///     - notificationCenter: The `UNUserNotificationCenter` to use for the notification requests.
    ///
    init(
        blogIdentifier: BlogIdentifier,
        store: BloggingRemindersStore? = nil,
        notificationCenter: UNUserNotificationCenter = .current()) throws {

        self.blogIdentifier = blogIdentifier
        self.store = try (store ?? Self.defaultStore())
        self.notificationCenter = notificationCenter
    }

    // MARK: - Scheduling

    /// Main method for scheduling blogging reminder notifications.  This method will take care of scheduling the local notifications and
    /// persisting the user-defined reminder schedule.
    ///
    /// - Parameters:
    ///     - schedule: the blogging reminders schedule.
    ///
    func schedule(_ schedule: Schedule) throws {
        unschedule(scheduledReminders)

        let scheduledReminders: BloggingRemindersStore.ScheduledReminders

        switch schedule {
        case .none:
            scheduledReminders = .none
        case .weekdays(let days):
            scheduledReminders = .weekdays(scheduled(days))
        }

        try store.save(scheduledReminders: scheduledReminders, for: blogIdentifier)
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
        dateComponents.calendar = Calendar.current

        dateComponents.weekday = weekday.rawValue
        dateComponents.hour = Weekday.defaultHour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)

        notificationCenter.add(request) { (error) in
            if let error = error {
                DDLogError(error.localizedDescription)
            }
        }

        return uuidString
    }

    // MARK: - Unscheduling

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

        notificationCenter.removePendingNotificationRequests(withIdentifiers: notificationIDs)
    }
}
