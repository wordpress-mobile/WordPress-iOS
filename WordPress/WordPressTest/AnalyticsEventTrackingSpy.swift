@testable import WordPress

class AnalyticsEventTrackingSpy: AnalyticsEventTracking {

    private(set) static var trackedEvents: [AnalyticsEvent] = []

    static func track(_ event: AnalyticsEvent) {
        trackedEvents.append(event)
    }

    static func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]) {
        track(.init(name: event.value, properties: properties as? [String: String] ?? [:]))
    }

    static func reset() {
        trackedEvents = []
    }
}
