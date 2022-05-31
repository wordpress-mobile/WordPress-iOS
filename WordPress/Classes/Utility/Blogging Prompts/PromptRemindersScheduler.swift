import Foundation
import UserNotifications

/// Encapsulates the local notification scheduling logic for Blogging Prompts.
///
class PromptRemindersScheduler {
    enum Errors: Error {
        case invalidSite
        case fileSaveError
        case unknown
    }

    private let promptsServiceFactory: BloggingPromptsServiceFactory
    private let notificationScheduler: NotificationScheduler
    private let pushAuthorizer: PushNotificationAuthorizer
    private let currentDateProvider: CurrentDateProvider
    private let localStore: LocalFileStore

    private static var gmtTimeZone = TimeZone(secondsFromGMT: 0)

    // MARK: Public Methods

    init(bloggingPromptsServiceFactory: BloggingPromptsServiceFactory = .init(),
         notificationScheduler: NotificationScheduler = UNUserNotificationCenter.current(),
         pushAuthorizer: PushNotificationAuthorizer = InteractiveNotificationsManager.shared,
         localStore: LocalFileStore = FileManager.default,
         currentDateProvider: CurrentDateProvider = DefaultCurrentDateProvider()) {
        self.promptsServiceFactory = bloggingPromptsServiceFactory
        self.notificationScheduler = notificationScheduler
        self.pushAuthorizer = pushAuthorizer
        self.localStore = localStore
        self.currentDateProvider = currentDateProvider
    }

    /// Schedule local notifications that will show prompts on selected weekdays based on the given `Schedule`.
    /// Prompt notifications will be bulk-scheduled for 2 weeks ahead, followed with static notifications for 2 weeks.
    ///
    /// Note: Calling this method will trigger the push notification authorization flow.
    ///
    /// - Parameters:
    ///   - schedule: The preferred notification schedule.
    ///   - blog: The blog that will upload the user's post.
    ///   - time: The user's preferred time to be notified.
    ///   - completion: Closure called after the process completes.
    func schedule(_ schedule: BloggingRemindersScheduler.Schedule, for blog: Blog, time: Date? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        guard schedule != .none else {
            // If there's no schedule, then we don't need to request authorization
            processSchedule(schedule, blog: blog, time: time, completion: completion)
            return
        }

        pushAuthorizer.requestAuthorization { [weak self] allowed in
            guard let self = self else {
                return
            }

            guard allowed else {
                completion(.failure(BloggingRemindersScheduler.Error.needsPermissionForPushNotifications))
                return
            }

            self.processSchedule(schedule, blog: blog, time: time, completion: completion)
        }
    }

    /// Removes all pending notifications for a given `siteID`.
    ///
    /// - Parameter blog: The blog that will have its pending reminder notifications cleared.
    func unschedule(for blog: Blog) {
        guard let siteID = blog.dotComID?.intValue,
              let receiptsForSite = fetchReceipts(for: siteID),
              !receiptsForSite.isEmpty else {
            return
        }

        notificationScheduler.removePendingNotificationRequests(withIdentifiers: receiptsForSite)
        try? deleteReceipts(for: siteID)
    }
}

// MARK: - Private Helpers

private extension PromptRemindersScheduler {
    typealias Schedule = BloggingRemindersScheduler.Schedule
    typealias Weekday = BloggingRemindersScheduler.Weekday

    /// A simple structure representing hour and minute.
    struct Time {
        let hour: Int
        let minute: Int

        init(hour: Int, minute: Int) {
            self.hour = hour
            self.minute = minute
        }

        init?(from date: Date?) {
            guard let dateComponents = date?.dateAndTimeComponents(),
                  let hourComponent = dateComponents.hour,
                  let minuteComponent = dateComponents.minute else {
                return nil
            }

            self.init(hour: hourComponent, minute: minuteComponent)
        }

        func compare(with date: Date) -> ComparisonResult {
            let hourToCompare = Calendar.current.component(.hour, from: date)
            let minuteToCompare = Calendar.current.component(.minute, from: date)

            if hour == hourToCompare {
                return NSNumber(value: minute).compare(NSNumber(value: minuteToCompare))
            }

            return NSNumber(value: hour).compare(NSNumber(value: hourToCompare))
        }
    }

    enum Constants {
        static let defaultTime = Time(hour: 10, minute: 0) // 10:00 AM
        static let promptsToFetch = 15 // fetch prompts for today + two weeks ahead
        static let staticNotificationMaxDays = 14 // schedule static notifications up to two weeks ahead
        static let notificationTitle = NSLocalizedString("Today's Prompt 💡", comment: "Title for a push notification showing today's blogging prompt.")
        static let staticNotificationContent = NSLocalizedString("Tap to load today's prompt...", comment: "Title for a push notification with fixed content"
                                                                 + " that invites the user to load today's blogging prompt.")
        static let defaultFileName = "PromptReminders.plist"
    }

    /// The actual implementation for the prompt notification scheduling.
    /// This method should only be called after push notifications have been authorized.
    ///
    /// - Parameters:
    ///   - schedule: The preferred notification schedule.
    ///   - blog: The blog that will upload the user's post.
    ///   - time: The user's preferred time to be notified.
    ///   - completion: Closure called after the process completes.
    func processSchedule(_ schedule: Schedule, blog: Blog, time: Date? = nil, completion: @escaping(Result<Void, Error>) -> Void) {
        // always reset pending notifications.
        unschedule(for: blog)

        guard case .weekdays(let weekdays) = schedule else {
            completion(.success(()))
            return
        }

        guard let siteID = blog.dotComID?.intValue,
              let promptsService = promptsServiceFactory.makeService(for: blog) else {
            completion(.failure(Errors.invalidSite))
            return
        }

        let reminderTime = Time(from: time) ?? Constants.defaultTime
        let currentDate = currentDateProvider.date()
        promptsService.fetchPrompts(from: currentDate, number: Constants.promptsToFetch) { [weak self] prompts in
            guard let self = self else {
                completion(.failure(Errors.unknown))
                return
            }

            // Step 1: Filter prompts based on the Schedule.
            let promptsToSchedule = prompts.sorted { $0.date < $1.date }.filter { prompt in
                guard let gmtTimeZone = Self.gmtTimeZone,
                      let weekdayComponent = Calendar.current.dateComponents(in: gmtTimeZone, from: prompt.date).weekday,
                      let weekday = Weekday(rawValue: weekdayComponent - 1) else { // Calendar.Component.weekday starts from 1 (Sunday)
                    return false
                }

                // only select prompts in the future that matches the weekdays listed in the schedule.
                // additionally, if today's prompt is included, only include it if the reminder time has not passed.
                return weekdays.contains(weekday)
                && (!prompt.inSameDay(as: currentDate) || reminderTime.compare(with: currentDate) == .orderedDescending)

            }

            // Step 2: Schedule prompt reminders.
            // The `lastScheduledPrompt` is stored to figure out the start date for static local notifications.
            var lastScheduledPrompt: BloggingPrompt? = nil
            var notificationIds = [String]()
            promptsToSchedule.forEach { prompt in
                guard let identifier = self.addLocalNotification(for: prompt, blog: blog, at: reminderTime) else {
                    return
                }
                notificationIds.append(identifier)
                lastScheduledPrompt = prompt
            }

            // Step 3: Schedule static notifications.
            // first, check the last reminder date. If there are no prompts scheduled (perhaps due to unavailable prompts),
            // this will schedule local notifications after the current date instead of the last scheduled date.
            let lastReminderDate: Date = {
                guard let lastScheduledPrompt = lastScheduledPrompt,
                      let lastReminderDateComponents = self.reminderDateComponents(for: lastScheduledPrompt, at: reminderTime),
                      let lastReminderDate = Calendar.current.date(from: lastReminderDateComponents) else {
                    return currentDate
                }

                return lastReminderDate
            }()

            if let staticNotificationIds = self.addStaticNotifications(after: lastReminderDate, with: schedule, time: reminderTime, blog: blog) {
                notificationIds.append(contentsOf: staticNotificationIds)
            }

            do {
                // Step 4: Store pending notification identifiers to local store.
                try self.saveReceipts(notificationIds, for: siteID)
            } catch {
                completion(.failure(error))
            }

            completion(.success(()))

        } failure: { error in
            completion(.failure(error ?? Errors.unknown))
        }
    }

    // MARK: Notification Scheduler

    /// Schedules the local notification for the given blogging prompt.
    ///
    /// - Parameters:
    ///   - prompt: The `BloggingPrompt` instance used to populate the content.
    ///   - blog: The user's blog.
    ///   - time: The preferred reminder time for the notification.
    /// - Returns: String representing the notification identifier.
    func addLocalNotification(for prompt: BloggingPrompt, blog: Blog, at time: Time) -> String? {
        guard let siteID = blog.dotComID?.intValue else {
            return nil
        }

        let content = UNMutableNotificationContent()
        content.title = Constants.notificationTitle
        content.subtitle = blog.title ?? String()
        content.body = prompt.text
        content.categoryIdentifier = InteractiveNotificationsManager.NoteCategoryDefinition.bloggingPrompt.rawValue
        content.userInfo = notificationPayload(for: blog, prompt: prompt)

        guard let reminderDateComponents = reminderDateComponents(for: prompt, at: time) else {
            return nil
        }

        return addLocalNotification(with: content, dateComponents: reminderDateComponents)
    }

    /// Converts the date from the `BloggingPrompt` to local date and time (matching the given `Time`), ignoring timezone conversion.
    /// For example, given:
    ///     - Local timezone: GMT-5
    ///     - BloggingPrompt date: 2022-05-01 00:00:00 +00:00
    ///     - Time: 10:30
    /// This method will return `DateComponents` for `2022-05-01 10:30:00 -05:00`.
    ///
    /// - Parameters:
    ///   - prompt: The `BloggingPrompt` instance used for date reference.
    ///   - time: The preferred time for the reminder.
    /// - Returns: Date components in local date and time.
    func reminderDateComponents(for prompt: BloggingPrompt, at time: Time) -> DateComponents? {
        guard let gmtTimeZone = Self.gmtTimeZone else {
            return nil
        }

        let gmtDateComponents = Calendar.current.dateComponents(in: gmtTimeZone, from: prompt.date)
        guard let year = gmtDateComponents.year,
              let month = gmtDateComponents.month,
              let day = gmtDateComponents.day else {
            return nil
        }

        return DateComponents(year: year, month: month, day: day, hour: time.hour, minute: time.minute)
    }

    /// Bulk schedule local notifications with static content for the given `Blog`.
    /// The notifications are scheduled after `afterDate` according to the provided `Schedule` and `Time`.
    ///
    /// - Parameters:
    ///   - afterDate: Local notifications will be scheduled after this date.
    ///   - schedule: The preferred notification schedule.
    ///   - time: The preferred reminder time.
    ///   - blog: The blog to be associated with the reminder notification.
    ///   - maxDays: Defines how far the reminders should be scheduled in the future.
    /// - Returns: An array of notification identifiers, or nil if there are logic errors.
    func addStaticNotifications(after afterDate: Date,
                                with schedule: Schedule,
                                time: Time,
                                blog: Blog,
                                maxDays: Int = Constants.staticNotificationMaxDays) -> [String]? {
        guard case .weekdays(let weekdays) = schedule,
              maxDays > 0,
              let maxDate = Calendar.current.date(byAdding: .day, value: maxDays, to: afterDate),
              let siteID = blog.dotComID?.intValue else {
            return nil
        }

        // create the notification content.
        // note that the userInfo dictionary excludes `promptID` since there is no prompt associated with it.
        let content = UNMutableNotificationContent()
        content.title = Constants.notificationTitle
        content.body = Constants.staticNotificationContent
        content.categoryIdentifier = InteractiveNotificationsManager.NoteCategoryDefinition.bloggingPrompt.rawValue
        content.userInfo = notificationPayload(for: blog)

        var date = afterDate
        var identifiers = [String]()
        while date < maxDate {
            // find the next dates matching the given schedule. The dates are sorted at the end to properly order the dates based on current date.
            // for example: given that today is Tuesday and the schedule is [.monday, .wednesday], the correct order for nextDates should be
            // [Wednesday this week, Monday next week].
            let nextDates: [Date] = weekdays.compactMap { weekday in
                guard let nextDate = Calendar.current.nextDate(after: date, matching: .init(weekday: weekday.rawValue + 1), matchingPolicy: .nextTime),
                      nextDate <= maxDate else {
                    return nil
                }
                return nextDate
            }.sorted()

            guard !nextDates.isEmpty else {
                break
            }

            // finally, schedule the local notifications.
            nextDates.forEach { nextDate in
                let components = Calendar.current.dateComponents([.year, .month, .day], from: nextDate)
                guard let year = components.year,
                      let month = components.month,
                      let day = components.day else {
                    return
                }

                let reminderDateComponents = DateComponents(year: year, month: month, day: day, hour: time.hour, minute: time.minute)
                let identifier = self.addLocalNotification(with: content, dateComponents: reminderDateComponents)

                identifiers.append(identifier)
                date = nextDate // move the `date` forward to get it closer to `maxDate`.
            }
        }

        return identifiers
    }

    /// Adds the local notification request to the notification scheduler.
    ///
    /// - Parameters:
    ///   - content: The local notification contents.
    ///   - dateComponents: When the local notification should occur.
    /// - Returns: A String representing the notification identifier.
    func addLocalNotification(with content: UNMutableNotificationContent, dateComponents: DateComponents) -> String {
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // schedule the local notification.
        notificationScheduler.add(request) { error in
            if let error = error {
                DDLogError("[PromptRemindersScheduler] Error adding notification request: \(error.localizedDescription)")
            }
        }

        return identifier
    }

    func notificationPayload(for blog: Blog, prompt: BloggingPrompt? = nil) -> [AnyHashable: Any] {
        guard let siteID = blog.dotComID?.intValue else {
            return [:]
        }

        var userInfo: [AnyHashable: Any] = [
            PushNotificationsManager.Notification.typeKey: PushNotificationsManager.Notification.bloggingPrompts,
            PushNotificationsManager.BloggingPromptPayload.siteIDKey: siteID
        ]

        if let prompt = prompt {
            userInfo[PushNotificationsManager.BloggingPromptPayload.promptIDKey] = Int(prompt.promptID)
        }

        return userInfo
    }

    // MARK: Local Storage

    func defaultFileURL() throws -> URL {
        let directoryURL = try FileManager.default.url(for: .applicationSupportDirectory,
                                                       in: .userDomainMask,
                                                       appropriateFor: nil,
                                                       create: true)

        return directoryURL.appendingPathComponent(Constants.defaultFileName)
    }

    /// Loads a dictionary containing all of the pending notification IDs for all sites.
    ///
    /// - Parameter fileURL: The file store location.
    /// - Returns: A dictionary containing `siteID` and an array of `String` representing pending notification IDs.
    func fetchAllReceipts(from fileURL: URL) throws -> [Int: [String]] {
        if !localStore.fileExists(at: fileURL) {
            let data = try PropertyListEncoder().encode([Int: [String]]())
            localStore.save(contents: data, at: fileURL)
        }

        let data = try localStore.data(from: fileURL)
        return try PropertyListDecoder().decode([Int: [String]].self, from: data)
    }

    /// Convenience method to fetch notification receipts for a given `siteID`.
    ///
    /// - Parameter siteID: The ID of the blog associated with the notification receipts.
    /// - Returns: An array of string representing the notification receipts.
    func fetchReceipts(for siteID: Int) -> [String]? {
        guard let allReceipts = try? fetchAllReceipts(from: defaultFileURL()),
              let receiptsForSite = allReceipts[siteID] else {
            return nil
        }

        return receiptsForSite
    }

    /// Updates the stored receipts under the given `siteID` key.
    /// When passing nil, this method will remove the receipts for `siteID` instead.
    ///
    /// - Parameters:
    ///   - receipts: A sequence of notification receipts to store.
    ///   - siteID: The `siteID` of the Blog associated with the prompt reminders.
    func saveReceipts(_ receipts: [String]?, for siteID: Int) throws {
        let fileURL = try defaultFileURL()
        var allReceipts = try fetchAllReceipts(from: fileURL)

        if let receipts = receipts, !receipts.isEmpty {
            allReceipts[siteID] = receipts
        } else {
            allReceipts.removeValue(forKey: siteID)
        }

        let data = try PropertyListEncoder().encode(allReceipts)
        guard localStore.save(contents: data, at: fileURL) else {
            throw Errors.fileSaveError
        }
    }

    /// Convenience method for deleting notification receipts.
    ///
    /// - Parameter siteID: The blog's ID associated with the notification receipts.
    func deleteReceipts(for siteID: Int) throws {
        try saveReceipts(nil, for: siteID)
    }
}

// MARK: - Current Date Provider

/// A wrapper protocol to get the current `Date`.
/// This is created to simplify unit testing.
///
protocol CurrentDateProvider {
    func date() -> Date
}

struct DefaultCurrentDateProvider: CurrentDateProvider {
    func date() -> Date {
        return Date()
    }
}

// MARK: - Local Store

/// A wrapper protocol intended for `FileManager`.
/// Created to simplify unit testing.
///
protocol LocalFileStore {
    func data(from url: URL) throws -> Data

    func fileExists(at url: URL) -> Bool

    @discardableResult
    func save(contents: Data, at url: URL) -> Bool
}

extension LocalFileStore {
    func data(from url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }
}

extension FileManager: LocalFileStore {
    func fileExists(at url: URL) -> Bool {
        return fileExists(atPath: url.path)
    }

    @discardableResult
    func save(contents: Data, at url: URL) -> Bool {
        return createFile(atPath: url.path, contents: contents)
    }
}
