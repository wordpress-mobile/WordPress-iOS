import Foundation

class BlogDashboardAnalytics {
    static let shared = BlogDashboardAnalytics()

    private var fired: [(WPAnalyticsEvent, [AnyHashable: String])] = []

    private init() {}

    func reset() {
        fired = []
    }

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
}
