extension AnalyticsEventTracking {

    static func track(_ event: DashboardDynamicCardAnalyticsEvent) {
        Self.track(AnalyticsEvent(name: event.name, properties: event.properties))
    }
}
