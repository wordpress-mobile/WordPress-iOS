import UserNotifications

/// Bridges the logic between Blogging Reminders and Blogging Prompts.
///
/// Users can switch between receiving Blogging Reminders or Blogging Prompts based on the switch toggle in the reminder sheet. They are both delivered
/// through local notifications, but the mechanism between the two is differentiated due to technical limitations. Blogging Prompts requires the content
/// of each notification to be different, and this is not possible if we want to use a repeating `UNCalendarNotificationTrigger`.
///
class ReminderScheduleCoordinator {

    // MARK: Dependencies

    private let bloggingRemindersScheduler: BloggingRemindersScheduler
    private let promptRemindersScheduler: PromptRemindersScheduler
    private let bloggingPromptsServiceFactory: BloggingPromptsServiceFactory

    // MARK: Public Methods

    init(bloggingRemindersScheduler: BloggingRemindersScheduler,
         promptRemindersScheduler: PromptRemindersScheduler,
         bloggingPromptsServiceFactory: BloggingPromptsServiceFactory = .init()) {
        self.bloggingRemindersScheduler = bloggingRemindersScheduler
        self.promptRemindersScheduler = promptRemindersScheduler
        self.bloggingPromptsServiceFactory = bloggingPromptsServiceFactory
    }

    convenience init(notificationScheduler: NotificationScheduler = UNUserNotificationCenter.current(),
                     pushNotificationAuthorizer: PushNotificationAuthorizer = InteractiveNotificationsManager.shared,
                     bloggingPromptsServiceFactory: BloggingPromptsServiceFactory = .init()) throws {

        let bloggingRemindersScheduler = try BloggingRemindersScheduler(notificationCenter: notificationScheduler,
                                                                        pushNotificationAuthorizer: pushNotificationAuthorizer)
        let promptRemindersScheduler = PromptRemindersScheduler(bloggingPromptsServiceFactory: bloggingPromptsServiceFactory,
                                                                notificationScheduler: notificationScheduler,
                                                                pushAuthorizer: pushNotificationAuthorizer)

        self.init(bloggingRemindersScheduler: bloggingRemindersScheduler,
                  promptRemindersScheduler: promptRemindersScheduler,
                  bloggingPromptsServiceFactory: bloggingPromptsServiceFactory)
    }

    /// Returns the user's reminder schedule for the given `blog`, based on the current reminder type.
    ///
    /// - Parameter blog: The blog associated with the reminders.
    /// - Returns: The user's preferred reminder schedule.
    func schedule(for blog: Blog) -> BloggingRemindersScheduler.Schedule {
        switch reminderType(for: blog) {
        case .bloggingReminders:
            return bloggingRemindersScheduler.schedule(for: blog)

        case .bloggingPrompts:
            guard let settings = promptReminderSettings(for: blog),
                  let reminderDays = settings.reminderDays,
                  !reminderDays.getActiveWeekdays().isEmpty else {
                return .none
            }

            return .weekdays(reminderDays.getActiveWeekdays())
        }
    }

    /// Returns the user's preferred time for the given `blog`, based on the current reminder type.
    ///
    /// - Parameter blog: The blog associated with the reminders.
    /// - Returns: The user's preferred time returned in `Date`.
    func scheduledTime(for blog: Blog) -> Date {
        switch reminderType(for: blog) {
        case .bloggingReminders:
            return bloggingRemindersScheduler.scheduledTime(for: blog)

        case .bloggingPrompts:
            guard let settings = promptReminderSettings(for: blog),
                  let dateForTime = settings.reminderTimeDate() else {
                return Constants.defaultTime
            }

            return dateForTime
        }
    }

    /// Schedules a reminder notification for the given `blog` based on the current reminder type.
    ///
    /// - Note: Calling this method will trigger the push notification authorization flow.
    ///
    /// - Parameters:
    ///   - schedule: The preferred notification schedule.
    ///   - blog: The blog that will upload the user's post.
    ///   - time: The user's preferred time to be notified.
    ///   - completion: Closure called after the process completes.
    func schedule(_ schedule: BloggingRemindersScheduler.Schedule,
                  for blog: Blog,
                  time: Date? = nil,
                  completion: @escaping (Result<Void, Swift.Error>) -> ()) {
        switch reminderType(for: blog) {
        case .bloggingReminders:
            bloggingRemindersScheduler.schedule(schedule, for: blog, time: time) { [weak self] result in
                // always unschedule prompt reminders in case the user toggled the switch.
                self?.promptRemindersScheduler.unschedule(for: blog)
                completion(result)
            }

        case .bloggingPrompts:
            promptRemindersScheduler.schedule(schedule, for: blog, time: time) { [weak self] result in
                // always unschedule blogging reminders in case the user toggled the switch.
                self?.bloggingRemindersScheduler.unschedule(for: blog)
                completion(result)
            }
        }
    }

    /// Unschedules all future reminders from the given `blog`.
    /// This applies to both Blogging Reminders and Blogging Prompts.
    ///
    /// - Parameter blog: The blog associated with the reminders.
    func unschedule(for blog: Blog) {
        bloggingRemindersScheduler.unschedule(for: blog)
        promptRemindersScheduler.unschedule(for: blog)
    }

}

// MARK: - Private Helpers

private extension ReminderScheduleCoordinator {

    enum ReminderType {
        case bloggingReminders
        case bloggingPrompts
    }

    enum Constants {
        static let defaultHour = 10
        static let defaultMinute = 0

        static var defaultTime: Date {
            let calendar = Calendar.current
            return calendar.date(from: DateComponents(calendar: calendar, hour: defaultHour, minute: defaultMinute)) ?? Date()
        }
    }

    func promptReminderSettings(for blog: Blog) -> BloggingPromptSettings? {
        guard let service = bloggingPromptsServiceFactory.makeService(for: blog) else {
            return nil
        }

        return service.localSettings
    }

    func reminderType(for blog: Blog) -> ReminderType {
        guard Feature.enabled(.bloggingPrompts),
              let settings = promptReminderSettings(for: blog),
              let context = settings.managedObjectContext else {
            return .bloggingReminders
        }

        var reminderType: ReminderType = .bloggingReminders
        context.performAndWait {
            reminderType = settings.promptRemindersEnabled ? .bloggingPrompts : .bloggingReminders
        }
        return reminderType
    }
}
