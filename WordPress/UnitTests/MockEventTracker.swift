@testable import WordPress

class MockEventTracker: EventTracker {
    var lastFiredEvent: WPAnalyticsEvent?

    func track(_ event: WPAnalyticsEvent) {
        lastFiredEvent = event
    }

    func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]) {
        lastFiredEvent = event
    }
}
