import Foundation
@testable import WordPress

class TestAnalytics: AppAnalytics {
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

    static func clean() {
        _tracked.removeAll()
    }

    static func trackedEventsCount() -> Int {
        return tracked.count
    }

    static func track(_ stat: WPAnalyticsStat, withProperties: [AnyHashable: Any]!) {
        let trackedStat = Tracked(stat: stat, properties: withProperties)
        _tracked.append(trackedStat)
    }
}
