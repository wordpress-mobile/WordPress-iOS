import WordPressShared

protocol PrivacySettingsAnalyticsTracking {

    func trackPrivacySettingsReportCrashesToggled(enabled: Bool)

    func trackPrivacyChoicesBannerSaveButtonTapped(analyticsEnabled: Bool)

    func track(_ event: PrivacySettingsAnalytics, properties: [String: String])
}

extension PrivacySettingsAnalyticsTracking {

    func trackPrivacySettingsReportCrashesToggled(enabled: Bool) {
        let props = ["enabled": enabled.stringLiteral]
        self.track(.privacySettingsReportCrashesToggled, properties: props)
    }

    func trackPrivacyChoicesBannerSaveButtonTapped(analyticsEnabled: Bool) {
        let props = ["analytics_enabled": analyticsEnabled.stringLiteral]
        self.track(.privacyChoicesBannerSaveButtonTapped, properties: props)
    }

    func track(_ event: PrivacySettingsAnalytics) {
        self.track(event, properties: [:])
    }
}

final class PrivacySettingsAnalyticsTracker: PrivacySettingsAnalyticsTracking {

    private let tracker: AnalyticsEventTracking.Type

    init(tracker: AnalyticsEventTracking.Type = WPAnalytics.self) {
        self.tracker = tracker
    }

    func track(_ event: PrivacySettingsAnalytics, properties: [String: String]) {
        let event = AnalyticsEvent(name: event.rawValue, properties: properties)
        tracker.track(event)
    }
}
