import Nimble
@testable import WordPress
import XCTest

class PrivacySettingsAnalyticsTrackerTests: XCTestCase {

    override func setUp() {
        super.setUp()

        // Because AnalyticsEventTrackingSpy logs events in a static var, we need to reset it between tests
        AnalyticsEventTrackingSpy.reset()
    }

    func test_trackPrivacySettingsReportCrashesToggled_enabled() {
        let tracker = PrivacySettingsAnalyticsTracker(tracker: AnalyticsEventTrackingSpy.self)

        tracker.trackPrivacySettingsReportCrashesToggled(enabled: true)

        expect(AnalyticsEventTrackingSpy.trackedEvents).to(haveCount(1))
        expect(AnalyticsEventTrackingSpy.trackedEvents).to(containElementSatisfying({ event in
            event.name == PrivacySettingsAnalytics.privacySettingsReportCrashesToggled.rawValue &&
            event.properties["enabled"] == true.stringLiteral
        }))
    }
}
