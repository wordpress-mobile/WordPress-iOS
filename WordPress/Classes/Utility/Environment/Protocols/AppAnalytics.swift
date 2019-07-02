
protocol AppAnalytics {
    static func track(_ stat: WPAnalyticsStat, withProperties: [AnyHashable: Any]!)
}

extension WPAppAnalytics: AppAnalytics {}
