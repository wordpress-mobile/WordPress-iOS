import Foundation

/// Analytics tracker for blogging reminders.
///
class BloggingRemindersTracker {
    enum BlogType: String {
        case wpcom
        case selfHosted = "self_hosted"
    }

    private enum SharedPropertyName: String {
        case blogType = "blog_type"
    }

    enum Event: String {
        // Flow events
        case flowCompleted = "blogging_reminders_flow_completed"
        case flowDismissed = "blogging_reminders_flow_dismissed"
        case flowStart = "blogging_reminders_flow_start"

        // Reminders scheduling events
        case remindersScheduled = "blogging_reminders_scheduled"
        case remindersCancelled = "blogging_reminders_cancelled"

        // Misc UI events
        case buttonPressed = "blogging_reminders_button_pressed"
        case screenShown = "blogging_reminders_screen_shown"
    }

    enum FlowStartSource: String {
        case publishFlow = "publish_flow"
        case blogSettings = "blog_settings"
        case notificationSettings = "notification_settings"
        case statsInsights = "stats_insights"
    }

    enum FlowDismissSource: String {
        case main
        case dayPicker = "day_picker"
        case enableNotifications = "enable_notifications"
        case timePicker = "time_picker"
    }

    enum Screen: String {
        case main
        case dayPicker = "day_picker"
        case allSet = "all_set"
        case enableNotifications = "enable_notifications"
    }

    enum Button: String {
        case `continue`
        case dismiss
        case notificationSettings
    }

    enum Property: String {
        case button = "button"
        case daysOfWeek = "days_of_week_count"
        case source = "source"
        case screen = "screen"
        case selectedTime = "selected_time"
    }

    /// The type of blog.
    ///
    let blogType: BlogType

    // MARK: - Initializers

    init(blogType: BlogType) {
        self.blogType = blogType
    }

    private func track(_ event: AnalyticsEvent) {
        WPAnalytics.track(event)
    }

    // MARK: - Tracking

    func buttonPressed(button: Button, screen: Screen) {
        let properties = [
            Property.button.rawValue: button.rawValue,
            Property.screen.rawValue: screen.rawValue,
        ]

        track(event(.buttonPressed, properties: properties))
    }

    func flowCompleted() {
        track(event(.flowCompleted, properties: [:]))
    }

    func flowDismissed(source: FlowDismissSource) {
        track(event(.flowDismissed, properties: [Property.source.rawValue: source.rawValue]))
    }

    func flowStarted(source: FlowStartSource) {
        track(event(.flowStart, properties: [Property.source.rawValue: source.rawValue]))

    }

    func scheduled(_ schedule: BloggingRemindersScheduler.Schedule, time: Date) {
        let event: AnalyticsEvent

        switch schedule {
        case .none:
            event = self.event(.remindersCancelled, properties: [:])
        case .weekdays(let days):
            event = self.event(.remindersScheduled,
                               properties: [Property.daysOfWeek.rawValue: "\(days.count)",
                                            Property.selectedTime.rawValue: time.toLocal24HTime()])
        }

        track(event)
    }

    func screenShown(_ screen: Screen) {
        track(event(.screenShown, properties: [Property.screen.rawValue: screen.rawValue]))
    }

    /// Private tracking method, which takes care of composing the tracking payload by adding the shared properties.
    ///
    private func event(_ event: Event, properties: [String: String]) -> AnalyticsEvent {
        let finalProperties = sharedProperties().merging(
            properties,
            uniquingKeysWith: { (first, second) in
                return first
        })

        return AnalyticsEvent(name: event.rawValue, properties: finalProperties)
    }

    // MARK: - Properties

    /// Returns the parameters that should be present for all events tracked by this tracker.
    ///
    private func sharedProperties() -> [String: String] {
        [SharedPropertyName.blogType.rawValue: self.blogType.rawValue]
    }
}
