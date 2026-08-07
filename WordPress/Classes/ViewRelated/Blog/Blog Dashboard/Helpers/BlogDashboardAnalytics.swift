import Foundation
import WordPressData
import WordPressShared

class BlogDashboardAnalytics {
    static let shared = BlogDashboardAnalytics()

    private var fired: [(WPAnalyticsEvent, [AnyHashable: String])] = []

    private init() {}

    /// Reset the history of fired events
    func reset() {
        fired = []
    }

    /// This will track the given event and properties given they haven't been
    /// triggered before.
    ///
    /// The My Site dashboard always shows exactly one site, so every card-shown
    /// event carries that site. `blog` is required so the site identifier is
    /// always attached and no future card can regress by omitting it.
    ///
    /// - Parameters:
    ///   - event: a `String` that represents the event name
    ///   - properties: a `Hash` that represents the properties
    ///   - blog: the `Blog` whose dashboard is being shown
    func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: String] = [:], blog: Blog) {
        if !fired.contains(where: { $0 == (event, properties) }) {
            fired.append((event, properties))
            WPAnalytics.track(event, properties: properties, blog: blog)
        }
    }

    static func trackContextualMenuAccessed(for card: BlogDashboardAnalyticPropertiesProviding) {
        WPAnalytics.track(.dashboardCardContextualMenuAccessed, properties: card.analyticProperties)
    }

    static func trackHideTapped(for card: BlogDashboardAnalyticPropertiesProviding) {
        WPAnalytics.track(.dashboardCardHideTapped, properties: card.analyticProperties)
    }

    static func trackContextualMenuAccessed(for card: DashboardCard) {
        self.trackContextualMenuAccessed(for: card as BlogDashboardAnalyticPropertiesProviding)
    }

    static func trackHideTapped(for card: DashboardCard) {
        self.trackHideTapped(for: card as BlogDashboardAnalyticPropertiesProviding)
    }
}
