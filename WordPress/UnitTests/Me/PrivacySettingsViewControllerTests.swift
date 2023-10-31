import Nimble
@testable import WordPress
import XCTest

final class PrivacySettingsViewControllerTests: XCTestCase {

    func testCrashReportingChangedLogsEvent() {
        let spy = PrivacySettingsAnalyticsTrackerSpy()
        let viewController = PrivacySettingsViewController(style: .grouped, analyticsTracker: spy)

        viewController.crashReportingChanged(true)

        expect(spy.trackedEvent).to(equal(.privacySettingsReportCrashesToggled))
        expect(spy.trackedEventProperties).to(equal(["enabled": true.stringLiteral]))
    }
}

final class PrivacySettingsAnalyticsTrackerSpy: PrivacySettingsAnalyticsTracking {

    private(set) var trackedEvent: PrivacySettingsAnalytics?
    private(set) var trackedEventProperties: [String: String]?

    func track(_ event: PrivacySettingsAnalytics, properties: [String: String]) {
        self.trackedEvent = event
        self.trackedEventProperties = properties
    }
}
