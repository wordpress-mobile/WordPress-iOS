import XCTest
@testable import WordPress

final class CompliancePopoverViewModelTests: CoreDataTestCase {
    let testDefaults = UserDefaults(suiteName: "compliance-popover-view-model-tests")

    override func setUp() {
        super.setUp()
        testDefaults?.removeObject(forKey: UserDefaults.didShowCompliancePopupKey)

        let windowManager = WindowManager(window: UIWindow())
        WordPressAuthenticationManager(
            windowManager: windowManager,
            remoteFeaturesStore: RemoteFeatureFlagStore()
        ).initializeWordPressAuthenticator()
    }

    override func tearDown() {
        super.tearDown()
        testDefaults?.removeObject(forKey: UserDefaults.didShowCompliancePopupKey)
    }

    /// Tests the tracking of the 'privacyChoicesBannerPresented' event when the privacy popover is displayed.
    /// It also validates that no additional event properties are being tracked.
    func testDidDisplayPopover() throws {
        // Given
        let defaults = try XCTUnwrap(testDefaults)
        let tracker = PrivacySettingsAnalyticsTrackerSpy()
        let sut = CompliancePopoverViewModel(defaults: defaults, contextManager: contextManager, analyticsTracker: tracker)

        // When
        sut.didDisplayPopover()

        // Then
        XCTAssertEqual(tracker.trackedEvent, .privacyChoicesBannerPresented)
        XCTAssertEqual(tracker.trackedEventProperties, [:])
    }

    func testDidTapSettingsUpdatesDefaults() throws {
        let defaults = try XCTUnwrap(testDefaults)
        let sut = CompliancePopoverViewModel(defaults: defaults, contextManager: contextManager)
        sut.didTapSettings()
        XCTAssert(defaults.didShowCompliancePopup)
    }

    func testDidTapSettingsInvokesCoordinatorNavigation() throws {
        let defaults = try XCTUnwrap(testDefaults)
        let mockCoordinator = MockCompliancePopoverCoordinator()
        let sut = CompliancePopoverViewModel(defaults: defaults, contextManager: contextManager)
        sut.coordinator = mockCoordinator
        sut.didTapSettings()
        XCTAssertEqual(mockCoordinator.navigateToSettingsCallCount, 1)
    }

    func testDidTapSaveInvokesDismissWhenAccountIDExists() throws {
        let defaults = try XCTUnwrap(testDefaults)
        let mockCoordinator = MockCompliancePopoverCoordinator()
        UserSettings.defaultDotComUUID = account().uuid
        let sut = CompliancePopoverViewModel(
            defaults: defaults,
            contextManager: contextManager
        )
        sut.coordinator = mockCoordinator
        sut.didTapSave()
        XCTAssertEqual(mockCoordinator.dismissCallCount, 1)
        XCTAssert(defaults.didShowCompliancePopup)
    }

    private func account() -> WPAccount {
        return AccountBuilder(contextManager.mainContext)
            .with(id: 1229)
            .with(username: "foobar")
            .with(email: "foo@automattic.com")
            .with(authToken: "9384rj398t34j98")
            .build()
    }
}

private class MockCompliancePopoverCoordinator: CompliancePopoverCoordinatorProtocol {
    private(set) var navigateToSettingsCallCount = 0
    private(set) var presentIfNeededCallCount = 0
    private(set) var dismissCallCount = 0

    @discardableResult
    func presentIfNeeded() async -> Bool {
        presentIfNeededCallCount += 1
        return true
    }

    func navigateToSettings() {
        navigateToSettingsCallCount += 1
    }

    func dismiss() {
        dismissCallCount += 1
    }
}
