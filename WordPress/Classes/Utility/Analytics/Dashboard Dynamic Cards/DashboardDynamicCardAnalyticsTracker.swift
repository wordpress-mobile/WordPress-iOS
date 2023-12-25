import Foundation

enum DashboardDynamicCardAnalyticsTrackingFrequency {
    case oncePerSession
    case multipleTimesPerSession
}

protocol DashboardDynamicCardAnalyticsTracking {
    func track(_ event: DashboardDynamicCardAnalyticsEvent, frequency: DashboardDynamicCardAnalyticsTrackingFrequency)
}

extension DashboardDynamicCardAnalyticsTracking {
    func track(_ event: DashboardDynamicCardAnalyticsEvent) {
        self.track(event, frequency: .multipleTimesPerSession)
    }
}

struct DashboardDynamicCardAnalyticsTracker: DashboardDynamicCardAnalyticsTracking {

    private static var firedAnalyticEvents = Set<DashboardDynamicCardAnalyticsEvent>()

    private let tracker: AnalyticsEventTracking.Type

    init(tracker: AnalyticsEventTracking.Type = WPAnalytics.self) {
        self.tracker = tracker
    }

    func track(_ event: DashboardDynamicCardAnalyticsEvent, frequency: DashboardDynamicCardAnalyticsTrackingFrequency) {
        guard frequency == .multipleTimesPerSession || (frequency == .oncePerSession && !Self.firedAnalyticEvents.contains(event)) else {
            return
        }
        self.tracker.track(.init(name: event.name, properties: event.properties))
        Self.firedAnalyticEvents.insert(event)
    }
}
