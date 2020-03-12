import Foundation
@testable import WordPress

class TestAnalyticsTracker: NSObject {
    struct Tracked {
        let stat: WPAnalyticsStat
        let properties: [AnyHashable: Any]

        func value<T>(for propertyName: String) -> T? {
            return properties[propertyName] as? T
        }
    }

    private static var _tracked: [Tracked] = []
    static var tracked: [Tracked] {
        return _tracked
    }

    static func setup() {
        WPAnalytics.register(TestAnalyticsTracker())
    }

    static func tearDown() {
        _tracked.removeAll()
        WPAnalytics.clearTrackers()
    }

    static func trackedEventsCount() -> Int {
        return tracked.count
    }

    private static func track(_ stat: WPAnalyticsStat, with properties: [AnyHashable: Any]? = nil) {
        let trackedStat = Tracked(stat: stat, properties: properties ?? [:])
        _tracked.append(trackedStat)
    }
}

extension TestAnalyticsTracker: WPAnalyticsTracker {
    func trackString(_ event: String) {

    }

    func trackString(_ event: String, withProperties properties: [AnyHashable: Any]!) {

    }

    func track(_ stat: WPAnalyticsStat) {
        TestAnalyticsTracker.track(stat)
    }

    func track(_ stat: WPAnalyticsStat, withProperties properties: [AnyHashable: Any]!) {
        TestAnalyticsTracker.track(stat, with: properties)
    }
}
