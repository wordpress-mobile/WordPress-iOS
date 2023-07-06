import XCTest
import Nimble

@testable import WordPress

final class CompliancePopoverViewControllerTests: CoreDataTestCase {

    /// Tests that the event `privacyChoicesBannerPresented` is tracked.
    func testTrackPrivacyChoicesBannerPresented() throws {
        // Given
        let tracker = PrivacySettingsAnalyticsTrackerSpy()
        let viewModel = try makeCompliancePopoverViewModelMock(tracker: tracker)
        let controller = CompliancePopoverViewController(viewModel: viewModel)

        // When
        controller.loadViewIfNeeded()

        // Then
        expect(tracker.trackedEvent).to(equal(.privacyChoicesBannerPresented))
        expect(tracker.trackedEventProperties).to(beEmpty())
    }

}

// MARK: - Mocks

extension CompliancePopoverViewControllerTests {

    func makeCompliancePopoverViewModelMock(tracker: PrivacySettingsAnalyticsTracking) throws -> CompliancePopoverViewModel {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "compliance-popover-mock"))
        return .init(defaults: defaults, contextManager: contextManager, analyticsTracker: tracker)
    }
}
