import Foundation

class NotificationEventTracker {
    enum Event: String {
        case notificationScheduled = "notification_scheduled"
        case notificationTapped = "notification_tapped"
    }

    enum Properties: String {
        case notificationType = "notification_type"
        case siteId = "site_id"
    }

    enum NotificationType: String {
        case bloggingReminders = "blogging_reminders"
        case weeklyRoundup = "weekly_roundup"
    }

    private let track: (AnalyticsEvent) -> Void

    init(trackMethod track: @escaping (AnalyticsEvent) -> Void = WPAnalytics.track) {
        self.track = track
    }

    func notificationScheduled(type: NotificationType, siteId: Int? = nil) {
        let event = AnalyticsEvent(
            name: Event.notificationScheduled.rawValue,
            properties: properties(for: type, siteId: siteId))

        track(event)
    }

    func notificationTapped(type: NotificationType, siteId: Int? = nil) {
        let event = AnalyticsEvent(
            name: Event.notificationTapped.rawValue,
            properties: properties(for: type, siteId: siteId))

        track(event)
    }

    private func properties(for type: NotificationType, siteId: Int?) -> [String: String] {
        var properties: [String: String] = [
            Properties.notificationType.rawValue: type.rawValue,
        ]

        if let siteId = siteId {
            properties[Properties.siteId.rawValue] = String(siteId)
        }

        return properties
    }
}
