@testable import WordPress

class AnalyticsEventTrackingSpy: AnalyticsEventTracking {

    private(set) static var trackedEvents: [AnalyticsEvent] = []

    static func track(_ event: AnalyticsEvent) {
        trackedEvents.append(event)
    }

    static func reset() {
        trackedEvents = []
    }
}
