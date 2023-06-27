import AutomatticTracks

final class PrivacySettingsAnalyticsTracker {

    // MARK: - API

    func trackPrivacySettingsReportCrashesToggled(enabled: Bool) {
        let props: Properties = ["enabled": enabled.stringLiteral]
        self.track(.privacyChoicesBannerSaveButtonTapped, properties: props)
    }

    func trackPrivacyChoicesBannerSaveButtonTapped(analyticsEnabled: Bool) {
        let props: Properties = ["analytics_enabled": analyticsEnabled.stringLiteral]
        self.track(.privacyChoicesBannerSaveButtonTapped, properties: props)
    }

    func track(_ event: PrivacySettingsAnalytics, properties: Properties = [:]) {
        let event = AnalyticsEvent(name: event.rawValue, properties: properties)
        WPAnalytics.track(event)
    }

    // MARK: - Types

    typealias Properties = [String: String]
}
