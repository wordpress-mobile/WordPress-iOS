import XCTest

@testable import WordPress

final class CompliancePopoverViewControllerTests: CoreDataTestCase {

    /// Tests that the method `viewModel.didDisplayPopover` is called on `viewDidLoad`.
    func testViewModelDidDisplayPopoverCalled() throws {
        // Given
        let viewModel = try makeCompliancePopoverViewModelSpy()
        let controller = CompliancePopoverViewController(viewModel: viewModel)

        // When
        controller.loadViewIfNeeded()

        // Then
        XCTAssertTrue(viewModel.didDisplayPopoverCalled)
    }

}

// MARK: - Test Doubles

private final class CompliancePopoverViewModelSpy: CompliancePopoverViewModel {

    private(set) var didDisplayPopoverCalled = false

    override func didDisplayPopover() {
        self.didDisplayPopoverCalled = true
    }
}

fileprivate extension CompliancePopoverViewControllerTests {

    func makeCompliancePopoverViewModelSpy() throws -> CompliancePopoverViewModelSpy {
        let tracker = PrivacySettingsAnalyticsTrackerSpy()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "compliance-popover-mock"))
        return CompliancePopoverViewModelSpy(defaults: defaults, contextManager: contextManager, analyticsTracker: tracker)
    }
}
