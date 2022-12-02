import Foundation

struct MigrationAnalyticsTracker {

    // MARK: - Track Method

    func track(_ event: MigrationEvent, properties: Properties = [:]) {
        let event = AnalyticsEvent(name: event.rawValue, properties: properties)
        WPAnalytics.track(event)
    }

    // MARK: - Types

    typealias Properties = [String: String]
}
