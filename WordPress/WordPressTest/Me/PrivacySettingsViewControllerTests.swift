import Nimble
@testable import WordPress
import XCTest

class PrivacySettingsViewControllerTests: XCTestCase {

    func testCrashReportingChangedLogsEvent() {
        let spy = PrivacySettingsAnalyticsTrackerSpy()
        let viewController = PrivacySettingsViewController(style: .grouped, analyticsTracker: spy)

        viewController.crashReportingChanged(true)

        expect(spy.trackedCrashReportingEnabled) == true
    }
}

class PrivacySettingsAnalyticsTrackerSpy: PrivacySettingsAnalyticsTracking {

    private(set) var trackedCrashReportingEnabled: Bool?
    private(set) var trackedAnalyticsEnabled: Bool?

    func trackPrivacySettingsReportCrashesToggled(enabled: Bool) {
        trackedCrashReportingEnabled = enabled
    }

    func trackPrivacyChoicesBannerSaveButtonTapped(analyticsEnabled: Bool) {
        trackedAnalyticsEnabled = analyticsEnabled
    }
}
