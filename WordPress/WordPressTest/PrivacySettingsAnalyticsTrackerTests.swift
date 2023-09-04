import Nimble
@testable import WordPress
import XCTest

class PrivacySettingsAnalyticsTrackerTests: XCTestCase {

    override func setUp() {
        super.setUp()

        // Because AnalyticsEventTrackingSpy logs events in a static var, we need to reset it between tests
        AnalyticsEventTrackingSpy.reset()
    }

    /// Tests that the event `trackPrivacyChoicesBannerSaveButtonTapped` is tracked with the correct properties.
    func test_privacySettingsAnalyticsTrackingToggled_enabled() {
        // Given
        let tracker = PrivacySettingsAnalyticsTracker(tracker: AnalyticsEventTrackingSpy.self)

        // When
        tracker.trackPrivacySettingsAnalyticsTrackingToggled(enabled: true)

        // Then
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(haveCount(1))
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(containElementSatisfying({ event in
            event.name == PrivacySettingsAnalytics.privacySettingsAnalyticsTrackingToggled.rawValue &&
            event.properties == ["enabled": true.stringLiteral]
        }))
    }

    /// Tests that the event `trackPrivacyChoicesBannerSaveButtonTapped` is tracked with the correct properties.
    func test_trackPrivacyChoicesBannerSaveButtonTapped_analyticsEnabled() {
        // Given
        let tracker = PrivacySettingsAnalyticsTracker(tracker: AnalyticsEventTrackingSpy.self)

        // When
        tracker.trackPrivacyChoicesBannerSaveButtonTapped(analyticsEnabled: true)

        // Then
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(haveCount(1))
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(containElementSatisfying({ event in
            event.name == PrivacySettingsAnalytics.privacyChoicesBannerSaveButtonTapped.rawValue &&
            event.properties == ["analytics_enabled": true.stringLiteral]
        }))
    }

    /// Tests that the event `privacyChoicesBannerSettingsButtonTapped` is tracked.
    func test_privacyChoicesBannerSettingsButtonTapped() {
        // Given
        let tracker = PrivacySettingsAnalyticsTracker(tracker: AnalyticsEventTrackingSpy.self)

        // When
        tracker.track(.privacyChoicesBannerSettingsButtonTapped)

        // Then
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(haveCount(1))
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(containElementSatisfying({ event in
            event.name == PrivacySettingsAnalytics.privacyChoicesBannerSettingsButtonTapped.rawValue &&
            event.properties.isEmpty
        }))
    }

    /// Tests that the event `privacySettingsReportCrashesToggled` is tracked with the correct properties.
    func test_trackPrivacySettingsReportCrashesToggled_enabled() {
        // Given
        let tracker = PrivacySettingsAnalyticsTracker(tracker: AnalyticsEventTrackingSpy.self)

        // When
        tracker.trackPrivacySettingsReportCrashesToggled(enabled: true)

        // Then
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(haveCount(1))
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(containElementSatisfying({ event in
            event.name == PrivacySettingsAnalytics.privacySettingsReportCrashesToggled.rawValue &&
            event.properties == ["enabled": true.stringLiteral]
        }))
    }
}
