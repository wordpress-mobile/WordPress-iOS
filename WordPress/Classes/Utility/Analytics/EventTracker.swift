/// Convenient tracking abstraction, which allows this to be a visible and injectable dependency.
///
protocol EventTracker {
    func track(_ event: WPAnalyticsEvent)
    func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any])
}

/// The default implementation, which is a thin wrapper over the actual `WPAnalytics` static methods.
struct DefaultEventTracker: EventTracker {
    func track(_ event: WPAnalyticsEvent) {
        WPAnalytics.track(event)
    }

    func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]) {
        WPAnalytics.track(event, properties: properties)
    }
}
