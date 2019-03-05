import UserNotifications

struct NotificationRemindersHelper {

    // MARK: - Get Reminder Details

    /// - returns: The Notification title for the specified reminder request.
    ///
    func reminderTitle(for request: UNNotificationRequest) -> String {
        guard let noteId = request.content.userInfo[RequestUserInfoKeys.notificationId.rawValue] as? String,
            let note = loadNotification(with: noteId),
            let subject = note.renderSubject()?.string else {
                return ""
        }

        return subject
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
                     forKey: DefaultsKeys.reminderIds.rawValue)
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
        let ids = UserDefaults.standard.array(forKey: DefaultsKeys.reminderIds.rawValue) as? [String]
        return ids ?? []
    }

    private enum DefaultsKeys: String {
        case reminderIds = "notification-reminder-ids"
    }

    private enum RequestUserInfoKeys: String {
        case notificationId = "note_id"
    }
}
