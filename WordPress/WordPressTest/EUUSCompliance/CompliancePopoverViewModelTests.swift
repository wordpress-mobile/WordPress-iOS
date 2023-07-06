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

    func testDidTapSettingsUpdatesDefaults() {
        guard let defaults = try? XCTUnwrap(testDefaults) else {
            return
        }
        let sut = CompliancePopoverViewModel(defaults: defaults, contextManager: contextManager)
        sut.didTapSettings()
        XCTAssert(defaults.didShowCompliancePopup)
    }

    func testDidTapSettingsInvokesCoordinatorNavigation() {
        guard let defaults = try? XCTUnwrap(testDefaults) else {
            return
        }
        let mockCoordinator = MockCompliancePopoverCoordinator()
        let sut = CompliancePopoverViewModel(defaults: defaults, contextManager: contextManager)
        sut.coordinator = mockCoordinator
        sut.didTapSettings()
        XCTAssertEqual(mockCoordinator.navigateToSettingsCallCount, 1)
    }

    func testDidTapSaveInvokesDismissWhenAccountIDExists() {
        guard let defaults = try? XCTUnwrap(testDefaults) else {
            return
        }
        let mockCoordinator = MockCompliancePopoverCoordinator()
        let sut = CompliancePopoverViewModel(
            defaults: defaults,
            contextManager: makeCoreDataStack()
        )
        sut.coordinator = mockCoordinator
        sut.didTapSave()
        XCTAssertEqual(mockCoordinator.dismissCallCount, 1)
        XCTAssert(defaults.didShowCompliancePopup)
    }

    private func makeCoreDataStack() -> ContextManager {
        let contextManager = ContextManager.forTesting()
        let account = AccountBuilder(contextManager)
            .with(id: 1229)
            .with(username: "foobar")
            .with(email: "foo@automattic.com")
            .with(authToken: "9384rj398t34j98")
            .build()
        UserSettings.defaultDotComUUID = account.uuid
        return contextManager
    }
}

private class MockCompliancePopoverCoordinator: CompliancePopoverCoordinatorProtocol {
    var navigateToSettingsCallCount = 0
    var presentIfNeededCallCount = 0
    var dismissCallCount = 0

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
