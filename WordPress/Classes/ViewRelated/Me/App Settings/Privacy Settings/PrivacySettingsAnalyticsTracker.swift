import WordPressShared

protocol PrivacySettingsAnalyticsTracking {

    func trackPrivacySettingsReportCrashesToggled(enabled: Bool)

    func trackPrivacyChoicesBannerSaveButtonTapped(analyticsEnabled: Bool)
}

final class PrivacySettingsAnalyticsTracker: PrivacySettingsAnalyticsTracking {

    private let tracker: AnalyticsEventTracking.Type

    init(tracker: AnalyticsEventTracking.Type = WPAnalytics.self) {
        self.tracker = tracker
    }

    // MARK: - API

    func trackPrivacySettingsReportCrashesToggled(enabled: Bool) {
        let props = ["enabled": enabled.stringLiteral]
        self.track(.privacyChoicesBannerSaveButtonTapped, properties: props)
    }

    func trackPrivacyChoicesBannerSaveButtonTapped(analyticsEnabled: Bool) {
        let props = ["analytics_enabled": analyticsEnabled.stringLiteral]
        self.track(.privacyChoicesBannerSaveButtonTapped, properties: props)
    }

    func track(_ event: PrivacySettingsAnalytics, properties: Properties = [:]) {
        let event = AnalyticsEvent(name: event.rawValue, properties: properties)
        tracker.track(event)
    }

    // MARK: - Types

    typealias Properties = [String: String]
}
