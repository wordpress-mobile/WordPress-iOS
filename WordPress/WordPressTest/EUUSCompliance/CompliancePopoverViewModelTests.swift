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
        return AccountBuilder(contextManager)
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

    func presentIfNeeded() {
        presentIfNeededCallCount += 1
    }

    func navigateToSettings() {
        navigateToSettingsCallCount += 1
    }

    func dismiss() {
        dismissCallCount += 1
    }
}
