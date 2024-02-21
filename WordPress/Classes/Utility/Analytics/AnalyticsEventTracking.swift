import WordPressShared

// Temporary workaround to abstract the WPAnalytics implementation detail.
//
// Unfortunately, track(_ event: AnalyticsEvent) is defined as an extension on WPAnalytics which is a concrete class.
// Until the method is moved to a protocol, i.e. at the WPAnalyticsTracker level, we'll have to wrap it like so.
protocol AnalyticsEventTracking {

    static func track(_ event: AnalyticsEvent)
}

extension AnalyticsEventTracking {

    static func track(_ event: WPAnalyticsEvent, properties: [String: String] = [:]) {
        track(.init(name: event.value, properties: properties))
    }
}

extension WPAnalytics: AnalyticsEventTracking {}
