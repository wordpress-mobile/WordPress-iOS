import Foundation
import UserNotifications

/// Encapsulates the local notification scheduling logic for Blogging Prompts.
///
class PromptRemindersScheduler {
    enum Errors: Error {
        case invalidSite
        case needsPushAuthorization
        case unknown
    }

    private let promptsServiceFactory: BloggingPromptsServiceFactory
    private let notificationScheduler: NotificationScheduler
    private let pushAuthorizer: PushNotificationAuthorizer
    private let currentDateProvider: CurrentDateProvider

    // MARK: Public Methods

    init(bloggingPromptsServiceFactory: BloggingPromptsServiceFactory = .init(),
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
                completion(.failure(Errors.needsPushAuthorization))
                return
            }

            self.processSchedule(schedule, blog: blog, time: time, completion: completion)
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

            if hour == hourToCompare {
                return NSNumber(value: minute).compare(NSNumber(value: minuteToCompare))
            }

            return NSNumber(value: hour).compare(NSNumber(value: hourToCompare))
        }
    }

    enum Constants {
        static let defaultTime = Time(hour: 10, minute: 0) // 10:00 AM
        static let promptsToFetch = 15 // fetch prompts for today + two weeks ahead
        static let notificationTitle = NSLocalizedString("Today's Prompt 💡", comment: "Title for a push notification showing today's blogging prompt.")
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
                let _ = self.addLocalNotification(for: promptToSchedule, blog: blog, at: reminderTime)
            }

            // TODO: Save notification identifiers to local store.

            // TODO: Schedule static notifications.

            completion(.success(()))

        } failure: { error in
            completion(.failure(error ?? Errors.unknown))
        }
    }

    /// Schedules the local notification.
    ///
    /// - Parameters:
    ///   - prompt: The `BloggingPrompt` instance used to populate the content.
    ///   - blog: The user's blog.
    ///   - time: The preferred reminder time for the notification.
    /// - Returns: String representing the notification identifier.
    func addLocalNotification(for prompt: BloggingPrompt, blog: Blog, at time: Time) -> String? {
        guard let gmtTimeZone = TimeZone(secondsFromGMT: 0) else {
            return nil
        }

        let gmtDateComponents = Calendar.current.dateComponents(in: gmtTimeZone, from: prompt.date)
        guard let year = gmtDateComponents.year,
              let month = gmtDateComponents.month,
              let day = gmtDateComponents.day else {
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
