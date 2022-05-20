import Foundation
import UserNotifications

/// Encapsulates the local notification scheduling logic for Blogging Prompts.
///
class PromptRemindersScheduler {
    enum Errors: Error {
        case invalidSite
        case unknown
    }

    private static var gmtTimeZone = TimeZone(secondsFromGMT: 0)!

    private let promptsServiceFactory: BloggingPromptsServiceFactory
    private let notificationScheduler: NotificationScheduler
    private let pushAuthorizer: PushNotificationAuthorizer
    private let currentDateProvider: CurrentDateProvider

    // MARK: Public Methods

    init(bloggingPromptsServiceFactory: BloggingPromptsServiceFactory,
         notificationScheduler: NotificationScheduler = UNUserNotificationCenter.current(),
         pushAuthorizer: PushNotificationAuthorizer = InteractiveNotificationsManager.shared,
         currentDateProvider: CurrentDateProvider = DefaultCurrentDateProvider()) {
        self.promptsServiceFactory = bloggingPromptsServiceFactory
        self.notificationScheduler = notificationScheduler
        self.pushAuthorizer = pushAuthorizer
        self.currentDateProvider = currentDateProvider
    }

    /// Schedule local notifications that will show prompts on selected weekdays based on the given `Schedule`.
    /// Prompt notifications will be bulk-scheduled for 2 weeks ahead.
    ///
    /// - Parameters:
    ///   - schedule: The preferred notification schedule.
    ///   - blog: The blog that will upload the user's post.
    ///   - time: The user's preferred time to be notified.
    ///   - completion: Closure called after the process completes.
    func schedule(_ schedule: BloggingRemindersScheduler.Schedule, for blog: Blog, time: Date? = nil, completion: @escaping(Result<Void, Error>) -> Void) {

        // TODO: Add push authorization before proceeding with the logic.

        guard case .weekdays(let weekdays) = schedule else {
            unschedule(for: blog)
            completion(.success(()))
            return
        }

        guard let promptsService = promptsServiceFactory.makeService(for: blog) else {
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

            // Filter prompts based on the Schedule.
            prompts.sorted { $0.date < $1.date }.filter { prompt in
                guard let weekdayComponent = Calendar.current.dateComponents([.weekday], from: prompt.date).weekday,
                      let weekday = Weekday(rawValue: weekdayComponent - 1) else { // Calendar.Component.weekday starts from 1 (Sunday)
                    return false
                }

                // only select prompts in the future that matches the weekdays listed in the schedule.
                // additionally, if today's prompt is included, only include it if the reminder time has not passed.
                return weekdays.contains(weekday)
                && (!prompt.inSameDay(as: currentDate) || reminderTime.compare(with: currentDate) == .orderedDescending)

            }.forEach { promptToSchedule in
                let _ = self.scheduleNotification(for: promptToSchedule, blog: blog, at: reminderTime)
            }

            // TODO: Save notification identifiers to local store.

            // TODO: Schedule static notifications.

            completion(.success(()))

        } failure: { error in
            completion(.failure(error ?? Errors.unknown))
        }
    }

    func unschedule(for blog: Blog) {
        // TODO: Implement
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

        func compare(with date: Date) -> ComparisonResult {
            let hourToCompare = Calendar.current.component(.hour, from: date)
            let minuteToCompare = Calendar.current.component(.minute, from: date)

            if hour == hourToCompare && minute == minuteToCompare {
                return .orderedSame
            } else if hour < hourToCompare || (hour < hourToCompare && minute < minuteToCompare) {
                return .orderedAscending
            }

            return .orderedDescending
        }
    }

    enum Constants {
        static let defaultTime = Time(hour: 10, minute: 0) // 10:00 AM
        static let promptsToFetch = 15 // fetch prompts for today + two weeks ahead
        static let notificationTitle = NSLocalizedString("Today's Prompt 💡", comment: "Title for a push notification showing today's blogging prompt.")
    }

    /// Schedules the local notification.
    ///
    /// - Parameters:
    ///   - prompt: The `BloggingPrompt` instance used to populate the content.
    ///   - blog: The user's blog.
    ///   - time: The preferred reminder time for the notification.
    /// - Returns: String representing the notification identifier.
    func scheduleNotification(for prompt: BloggingPrompt, blog: Blog, at time: Time) -> String? {
        let utcDateComponents = Calendar.current.dateComponents(in: Self.gmtTimeZone, from: prompt.date)
        guard let year = utcDateComponents.year,
              let month = utcDateComponents.month,
              let day = utcDateComponents.day else {
            return nil
        }

        let content = UNMutableNotificationContent()
        content.title = Constants.notificationTitle
        content.subtitle = blog.title ?? String()
        content.body = prompt.text

        // craft the notification trigger.
        let reminderDateComponents = DateComponents(year: year, month: month, day: day, hour: time.hour, minute: time.minute)
        let trigger = UNCalendarNotificationTrigger(dateMatching: reminderDateComponents, repeats: false)
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // schedule the notification.
        notificationScheduler.add(request) { error in
            if let error = error {
                DDLogError("[PromptRemindersScheduler] Error adding notification request: \(error.localizedDescription)")
            }
        }

        return identifier
    }
}

private extension PromptRemindersScheduler.Time {
    init?(from date: Date?) {
        guard let dateComponents = date?.dateAndTimeComponents(),
              let hourComponent = dateComponents.hour,
              let minuteComponent = dateComponents.minute else {
            return nil
        }

        self.init(hour: hourComponent, minute: minuteComponent)
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
