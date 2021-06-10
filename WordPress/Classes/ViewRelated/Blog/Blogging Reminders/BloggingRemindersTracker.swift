import Foundation

/// Analytics tracker for blogging reminders.
///
class BloggingRemindersTracker {
    enum BlogType: String {
        case wpcom
        case selfHosted = "self_hosted"
    }

    private enum SharedPropertyName: String {
        case blogID = "blog_id"
        case blogType = "blog_type"
        case blogURL = "blog_url"
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

        static let propertyName = "source"
    }

    enum FlowDismissSource: String {
        case main
        case dayPicker = "day_picker"

        static let propertyName = "source"
    }

    enum Screen: String {
        case main
        case dayPicker = "day_picker"
        case allSet = "all_set"

        static let propertyName = "screen"
    }

    enum Button: String {
        case `continue`
        case dismiss

        static let propertyName = "button"
    }

    let blogID: Int?
    let blogType: BlogType
    let blogURL: String

    // MARK: - Initializers

    convenience init(for blog: Blog) {
        let blogType: BloggingRemindersTracker.BlogType = blog.isHostedAtWPcom ? .wpcom : .selfHosted
        // This isn't great but if we don't have a blog URL at this point there isn't much we can do.
        let blogURL = blog.url ?? ""
        let blogID: Int? = {
            guard let blogID = blog.dotComID else {
                return nil
            }

            return blogID.intValue
        }()

        self.init(blogType: blogType, blogURL: blogURL, blogID: blogID)
    }

    init(blogType: BlogType, blogURL: String, blogID: Int?) {
        self.blogID = blogID
        self.blogType = blogType
        self.blogURL = blogURL
    }

    private func track(_ event: AnalyticsEvent) {
        WPAnalytics.track(event)
    }

    // MARK: - Tracking

    func buttonPressed(button: Button, screen: Screen) {
        let properties = [
            Button.propertyName: button.rawValue,
            Screen.propertyName: screen.rawValue,
        ]

        track(event(.buttonPressed, properties: properties))
    }

    func flowCompleted() {
        track(event(.flowCompleted, properties: [:]))
    }

    func flowDismissed(source: FlowDismissSource) {
        track(event(.flowDismissed, properties: [FlowDismissSource.propertyName: source.rawValue]))
    }

    func flowStarted(source: FlowStartSource) {
        track(event(.flowStart, properties: [FlowStartSource.propertyName: source.rawValue]))

    }

    func screenShown(_ screen: Screen) {
        track(event(.screenShown, properties: [Screen.propertyName: screen.rawValue]))
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
