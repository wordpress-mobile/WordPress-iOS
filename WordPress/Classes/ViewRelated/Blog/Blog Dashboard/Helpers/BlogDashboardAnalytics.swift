import Foundation

class BlogDashboardAnalytics {
    static let shared = BlogDashboardAnalytics()

    private var fired: [WPAnalyticsEvent] = []

    private init() {}

    func reset() {
        fired = []
    }

    func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any] = [:], blog: Blog? = nil) {
        if !fired.contains(event) {
            fired.append(event)

            if let blog = blog {
                WPAnalytics.track(event, properties: properties, blog: blog)
            } else {
                WPAnalytics.track(event, properties: properties)
            }
        }
    }
}
