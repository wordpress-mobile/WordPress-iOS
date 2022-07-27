import Foundation

extension WPAnalytics {

    static let WPAppAnalyticsKeyQuickStartSiteType: String = "site_type"

    /// Track a Quick Start event
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `WPAnalyticsEvent` that represents the Quick Start event to track
    /// - Parameter properties: a `Hash` that represents the properties
    /// - Parameter blog: a `Blog` to which the Quick Start event relates to. Used to determine the Quick Start Type
    ///
    static func trackQuickStartEvent(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any] = [:], blog: Blog) {
        var props = properties
        props[WPAppAnalyticsKeyQuickStartSiteType] = blog.quickStartType.key
        WPAnalytics.track(event, properties: props)
    }

    /// Track a Quick Start stat
    ///
    /// This will call each registered tracker and fire the given stat
    /// - Parameter stat: a `WPAnalyticsStat` that represents the Quick Start stat to track
    /// - Parameter properties: a `Hash` that represents the properties
    /// - Parameter blog: a `Blog` to which the Quick Start stat relates to. Used to determine the Quick Start Type
    ///
    static func trackQuickStartStat(_ stat: WPAnalyticsStat, properties: [AnyHashable: Any] = [:], blog: Blog) {
        var props = properties
        props[WPAppAnalyticsKeyQuickStartSiteType] = blog.quickStartType.key
        WPAnalytics.track(stat, withProperties: props)
    }

    /// Track a Quick Start stat in Obj-C
    ///
    /// This will call each registered tracker and fire the given stat
    /// - Parameter stat: a `WPAnalyticsStat` that represents the Quick Start stat to track
    /// - Parameter blog: a `Blog` to which the Quick Start stat relates to. Used to determine the Quick Start Type
    ///
    @objc static func trackQuickStartStat(_ stat: WPAnalyticsStat, blog: Blog) {
        let props = [WPAppAnalyticsKeyQuickStartSiteType: blog.quickStartType.key]
        WPAnalytics.track(stat, withProperties: props)
    }
}
