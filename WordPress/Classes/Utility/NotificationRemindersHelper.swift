import UserNotifications


struct NotificationRemindersHelper {

    // MARK: - Set a Reminder

    /// Schedules a reminder local notification for the specified time interval in the future.
    ///
    /// - parameters:
    ///     - time: A NotificationReminderPeriod after which the local notification should be displayed
    ///     - note: The Notification that the user should be reminded about
    ///     - completion: Called after the notification has been scheduled. Passed `true` if the
    ///                   notification was successfully scheduled, otherwise false.
    ///
    func remindMe(in time: NotificationReminderPeriod, about note: Notification, completion: ((Bool) -> Void)? = nil) {
        guard let components = time.dateComponents else {
            completion?(false)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Notification Reminder", comment: "Title of a reminder notification displayed to the user")
        if let subject = note.renderSubject()?.string {
            content.body = subject
        }
        content.categoryIdentifier = RequestKeys.category
        content.sound = UNNotificationSound.default
        content.userInfo = [
            RequestKeys.type: RequestKeys.typeValue,
            RequestKeys.notificationId: note.notificationId
        ]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = UUID().uuidString
        let notificationRequest = UNNotificationRequest(identifier: identifier,
                                                        content: content,
                                                        trigger: trigger)

        UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: { error in
            if let error = error {
                DDLogError("Unable to add reminder notification request (\(error), \(error.localizedDescription))")
                completion?(false)
            } else {
                self.trackReminder(withId: identifier)
                completion?(true)
            }
        })
    }

    // MARK: - Get Reminder Details

    /// - returns: The Notification title for the specified reminder request.
    ///
    func reminderTitle(for request: UNNotificationRequest) -> String {
        guard let noteId = reminderNotificationId(from: request.content.userInfo),
            let note = loadNotification(with: noteId),
            let subject = note.renderSubject()?.string else {
                return ""
        }

        return subject
    }

    /// - returns: A Notification identifier contained within the provided userInfo,
    ///   if one is present.
    ///
    func reminderNotificationId(from userInfo: [AnyHashable: Any]) -> String? {
        return userInfo[RequestKeys.notificationId] as? String
    }

    /// - returns: The trigger date for the specified reminder request.
    ///
    func reminderTriggerDate(for request: UNNotificationRequest) -> Date? {
        let trigger = request.trigger as? UNCalendarNotificationTrigger
        return trigger?.nextTriggerDate()
    }

    /// Fetches the Notification with the specified ID from Core Data.
    ///
    private func loadNotification(with noteId: String) -> Notification? {
        let predicate = NSPredicate(format: "(notificationId == %@)", noteId)

        return ContextManager.shared.mainContext.firstObject(ofType: Notification.self,
                                                             matching: predicate)
    }

    // MARK: - Managing Reminders

    /// Logs the specified reminder ID, used when fetching and filtering
    /// pending reminders. A reminder ID must be tracked using this
    /// method for it to be returned by `getPendingReminders`.
    ///
    /// - parameter id: The identifier of a UNNotificationRequest
    ///
    func trackReminder(withId id: String) {
        let defaults = UserDefaults.standard

        var ids = reminderIds
        ids.append(id)
        defaults.set(ids as Any,
                     forKey: DefaultsKeys.reminderIds)
    }

    /// Checks for the presence of pending reminders.
    ///
    /// - parameter completion: The completion block is called with `true` if
    ///   there are any pending reminders in the notification center, otherwise `false`.
    ///
    func hasPendingReminders(_ completion: @escaping ((Bool) -> Void)) {
        getPendingReminders { requests in
            completion(requests.count > 0)
        }
    }

    /// Fetches a list of all pending reminders whose identifiers have previously
    /// been tracked by `trackReminder(withId:)`, and with valid trigger dates.
    ///
    /// - parameter completion: The completion block is called with a list of
    ///   notification reminder requests.
    ///
    func getPendingReminders(_ completion: @escaping (([UNNotificationRequest]) -> Void)) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = self.reminderIds
            let filtered = requests.filter({ request in
                guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {
                    return false
                }

                let hasReminderId = ids.contains(request.identifier)
                let hasPendingDate = trigger.nextTriggerDate() != nil

                return hasReminderId && hasPendingDate
            })
            
            let sorted = self.sorted(requests: filtered)
            completion(sorted)
        }
    }

    /// Cancels the specified notification request.
    ///
    func cancelReminder(_ request: UNNotificationRequest) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
    }

    /// Cancels all reminders whose identifiers have previously been tracked by `trackReminder(withId:)`.
    ///
    func cancelAllReminders() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: reminderIds)
    }

    /// Sorts the provided requests by trigger date in ascending order (most recent first).
    ///
    private func sorted(requests: [UNNotificationRequest]) -> [UNNotificationRequest] {
        return requests.sorted(by: { (request1, request2) -> Bool in
            guard let trigger1 = request1.trigger as? UNCalendarNotificationTrigger,
                let trigger2 = request2.trigger as? UNCalendarNotificationTrigger,
                let date1 = trigger1.nextTriggerDate(),
                let date2 = trigger2.nextTriggerDate() else {
                    return true
            }

            return date1 < date2
        })
    }

    // TODO: Add method to clear out reminder IDs that are no longer valid.

    /// An array of all reminder identifiers that are currently being tracked.
    ///
    private var reminderIds: [String] {
        let ids = UserDefaults.standard.array(forKey: DefaultsKeys.reminderIds) as? [String]
        return ids ?? []
    }

    private enum DefaultsKeys {
        static let reminderIds = "notification-reminder-ids"
    }

    enum RequestKeys {
        static let category = "notification-reminder"
        static let notificationId = "note_id"
        static let type = "type"
        static let typeValue = "local"
    }
}

/// Encapsulates the period after which a reminder should be displayed.
///
enum NotificationReminderPeriod: CaseIterable {
    case in20minutes
    case in1hour
    case in3hours
    case tomorrow   // 9am tomorrow
    case nextWeek   // 9am on the next Monday

    /// A title describing the time period, for display to the user.
    ///
    var displayTitle: String {
        switch self {
        case .in20minutes:
            return NSLocalizedString("In 20 Minutes", comment: "Title of a reminder option that sets a reminder in 20 minutes time")
        case .in1hour:
            return NSLocalizedString("In 1 Hour", comment: "Title of a reminder option that sets a reminder in 1 hours time")
        case .in3hours:
            return NSLocalizedString("In 3 Hours", comment: "Title of a reminder option that sets a reminder in 3 hours time")
        case .tomorrow:
            return NSLocalizedString("Tomorrow", comment: "Title of a reminder option that sets a reminder for 9am tomorrow.")
        case .nextWeek:
            return NSLocalizedString("Next Week", comment: "Title of a reminder option that sets a reminder for 9am the following Monday.")
        }
    }

    /// Date components representing the time period. Used to schedule a reminder.
    ///
    var dateComponents: DateComponents? {
        var components = DateComponents()

        switch self {
        case .in20minutes:
            components.minute = 20
            return Date.today.addingComponents(components)?.timeAndDateComponents
        case .in1hour:
            components.hour = 1
            return Date.today.addingComponents(components)?.timeAndDateComponents
        case .in3hours:
            components.hour = 3
            return Date.today.addingComponents(components)?.timeAndDateComponents
        case .tomorrow:
            components.day = 1
            guard let tomorrow = Date.today.addingComponents(components),
                let date = Calendar.current.date(bySettingHour: ComponentValues.hours9am, minute: 0, second: 0, of: tomorrow) else {
                    return nil
            }
            return date.timeAndDateComponents
        case .nextWeek:
            components.weekday = ComponentValues.weekdayMonday
            components.hour = ComponentValues.hours9am
            return components
        }
    }

    private enum ComponentValues {
        static let hours9am = 9
        static let weekdayMonday = 2
    }
}

private extension Date {
    static var today: Date {
        return Date()
    }

    var timeAndDateComponents: DateComponents {
        return Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second],
                                               from: self)
    }

    func addingComponents(_ components: DateComponents) -> Date? {
        return Calendar.current.date(byAdding: components, to: self)
    }
}
