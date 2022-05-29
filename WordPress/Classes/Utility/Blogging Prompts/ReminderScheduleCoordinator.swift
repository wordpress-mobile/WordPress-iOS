import UserNotifications

/// Abstraction layer between Blogging Reminders and Blogging Prompts.
///
class ReminderScheduleCoordinator {

    // MARK: Dependencies

    private let notificationScheduler: NotificationScheduler
    private let pushNotificationAuthorizer: PushNotificationAuthorizer
    private let bloggingPromptsServiceFactory: BloggingPromptsServiceFactory

    private let bloggingRemindersScheduler: BloggingRemindersScheduler
    private let promptRemindersScheduler: PromptRemindersScheduler

    // MARK: Public Methods

    init(notificationScheduler: NotificationScheduler = UNUserNotificationCenter.current(),
         pushNotificationAuthorizer: PushNotificationAuthorizer = InteractiveNotificationsManager.shared,
         bloggingPromptsServiceFactory: BloggingPromptsServiceFactory = .init()) throws {

        // initialize the dependencies
        self.notificationScheduler = notificationScheduler
        self.pushNotificationAuthorizer = pushNotificationAuthorizer
        self.bloggingPromptsServiceFactory = bloggingPromptsServiceFactory

        // initialize the schedulers
        self.bloggingRemindersScheduler = try .init(notificationCenter: notificationScheduler,
                                                    pushNotificationAuthorizer: pushNotificationAuthorizer)
        self.promptRemindersScheduler = .init(bloggingPromptsServiceFactory: bloggingPromptsServiceFactory,
                                              notificationScheduler: notificationScheduler,
                                              pushAuthorizer: pushNotificationAuthorizer)
    }


    func schedule(for blog: Blog) -> BloggingRemindersScheduler.Schedule {
        switch reminderType(for: blog) {
        case .bloggingReminders:
            return bloggingRemindersScheduler.schedule(for: blog)

        case .bloggingPrompts:
            return .none
        }
    }

    func scheduledTime(for blog: Blog) -> Date {
        switch reminderType(for: blog) {
        case .bloggingReminders:
            return bloggingRemindersScheduler.scheduledTime(for: blog)

        case .bloggingPrompts:
            return Date() // TODO.
        }
    }

    func schedule(_ schedule: BloggingRemindersScheduler.Schedule,
                  for blog: Blog,
                  time: Date? = nil,
                  completion: @escaping (Result<Void, Swift.Error>) -> ()) {
        switch reminderType(for: blog) {
        case .bloggingReminders:
            bloggingRemindersScheduler.schedule(schedule, for: blog, time: time, completion: completion)

        case .bloggingPrompts:
            promptRemindersScheduler.schedule(schedule, for: blog, time: time, completion: completion)
        }
    }

}

// MARK: - Private Helpers

private extension ReminderScheduleCoordinator {

    enum ReminderType {
        case bloggingReminders
        case bloggingPrompts
    }

    func promptReminderSettings(for blog: Blog) -> BloggingPromptSettings? {
        guard Feature.enabled(.bloggingPrompts),
              let service = bloggingPromptsServiceFactory.makeService(for: blog) else {
            return nil
        }

        return service.localSettings
    }

    func reminderType(for blog: Blog) -> ReminderType {
        if let settings = promptReminderSettings(for: blog),
           settings.promptRemindersEnabled {
            return .bloggingPrompts
        }

        return .bloggingReminders
    }
}
