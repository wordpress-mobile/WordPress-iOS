import Foundation

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
    /// - Parameters:
    ///   - event: a `String` that represents the event name
    ///   - properties: a `Hash` that represents the properties
    ///   - blog: a `Blog` asssociated with the event
    func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: String] = [:], blog: Blog? = nil) {
        if !fired.contains(where: { $0 == (event, properties) }) {
            fired.append((event, properties))

            if let blog = blog {
                WPAnalytics.track(event, properties: properties, blog: blog)
            } else {
                WPAnalytics.track(event, properties: properties)
            }
        }
    }

    static func trackContextualMenuAccessed(for propertiesProvider: BlogDashboardAnalyticPropertiesProviding) {
        WPAnalytics.track(.dashboardCardContextualMenuAccessed, properties: propertiesProvider.blogDashboardAnalyticProperties)
    }

    static func trackHideTapped(for propertiesProvider: BlogDashboardAnalyticPropertiesProviding) {
        WPAnalytics.track(.dashboardCardHideTapped, properties: propertiesProvider.blogDashboardAnalyticProperties)
    }

    static func trackContextualMenuAccessed(for card: DashboardCard) {
        Self.trackContextualMenuAccessed(for: card as BlogDashboardAnalyticPropertiesProviding)
    }

    static func trackHideTapped(for card: DashboardCard) {
        Self.trackHideTapped(for: card as BlogDashboardAnalyticPropertiesProviding)
    }
}
