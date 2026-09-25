import Foundation
import XCTest
import WordPressShared

@testable import WordPress
@testable import WordPressData

final class RootViewCoordinatorTests: XCTestCase {
    private var sut: RootViewCoordinator!
    private var windowManager: WindowManagerMock!
    private var contextManager: ContextManager!

    override func setUp() {
        super.setUp()
        contextManager = ContextManager.forTesting()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        windowManager = WindowManagerMock(window: .init())
        sut = RootViewCoordinator(
            featureFlagStore: RemoteFeatureFlagStoreMock(),
            windowManager: windowManager
        )
    }

    override func tearDown() {
        super.tearDown()
        windowManager = nil
        sut = nil
        contextManager = nil
        UserSettings.defaultDotComUUID = nil
        JetpackFeaturesRemovalCoordinator.currentAppUIType = nil
    }

    func testAppUIDeallocatedAfterLogout() {
        sut.showAppUI()
        let mainRootViewController = windowManager.presentedViewController
        XCTAssertNotNil(mainRootViewController)

        sut.showSignInUI()

        addTeardownBlock { [weak mainRootViewController] in
            XCTAssertNil(mainRootViewController)
        }
    }

    func testReaderTabsUIShowsLiveTabs() throws {
        try XCTSkipIf(UIDevice.isPad(), "The iPad presenter ignores the app UI type")

        // Given
        signInToWordPressDotCom()

        // When
        sut = makeCoordinator(isReaderAndNotificationsEnabled: true)
        sut.showAppUI()

        // Then
        let tabBarController = try XCTUnwrap(windowManager.presentedViewController as? WPTabBarController)
        XCTAssertFalse(tabBarController.shouldUseStaticScreens)
        XCTAssertEqual(tabBarController.notificationsViewController?.scope, .reader)
    }

    func testSignInResolvesReaderTabsUIBeforeTheUIReloads() {
        // Given
        let featureFlagStore = RemoteFeatureFlagStoreMock()
        featureFlagStore.removalPhaseSelfHosted = true
        sut = makeCoordinator(isReaderAndNotificationsEnabled: true, featureFlagStore: featureFlagStore)
        sut.showAppUI()

        // When
        signInToWordPressDotCom()
        postAccountChangeNotification()

        // Then
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .readerTabs)
        XCTAssertFalse(JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled())
        XCTAssertFalse(windowManager.didShowUI)

        // The simplified UI is still shown, so My Site must be able to rebuild it.
        XCTAssertTrue(sut.reloadUIIfNeeded(blog: nil))
        XCTAssertTrue(windowManager.didShowUI)
    }

    func testSignOutRebuildsTheUIOnReload() {
        // Given
        let featureFlagStore = RemoteFeatureFlagStoreMock()
        featureFlagStore.removalPhaseSelfHosted = true
        signInToWordPressDotCom()
        sut = makeCoordinator(isReaderAndNotificationsEnabled: true, featureFlagStore: featureFlagStore)
        sut.showAppUI()

        // When
        UserSettings.defaultDotComUUID = nil
        postAccountChangeNotification()

        // Then
        XCTAssertTrue(sut.reloadUIIfNeeded(blog: nil))
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .simplified)
    }

    func testSignInKeepsLaunchUITypeUntilReloadWhenFlagIsOff() {
        // Given
        let featureFlagStore = RemoteFeatureFlagStoreMock()
        featureFlagStore.removalPhaseStaticScreens = true
        sut = makeCoordinator(isReaderAndNotificationsEnabled: false, featureFlagStore: featureFlagStore)
        sut.showAppUI()

        // When
        signInToWordPressDotCom()
        postAccountChangeNotification()

        // Then
        XCTAssertTrue(sut.reloadUIIfNeeded(blog: nil))
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreens)
    }

    func testReloadUIWhenSwitchingToReaderTabsUI() {
        // Given
        sut = makeCoordinator(isReaderAndNotificationsEnabled: true)
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .normal)

        // When
        signInToWordPressDotCom()
        let didReload = sut.reloadUIIfNeeded(blog: nil)

        // Then
        XCTAssertTrue(didReload)
        XCTAssertTrue(windowManager.didShowUI)
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .readerTabs)
    }

    func testReloadUIWhenSwitchingFromReaderTabsUI() {
        // Given
        signInToWordPressDotCom()
        sut = makeCoordinator(isReaderAndNotificationsEnabled: true)
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .readerTabs)

        // When
        UserSettings.defaultDotComUUID = nil
        let didReload = sut.reloadUIIfNeeded(blog: nil)

        // Then
        XCTAssertTrue(didReload)
        XCTAssertTrue(windowManager.didShowUI)
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .normal)
    }

    // MARK: - Helpers

    private func makeCoordinator(
        isReaderAndNotificationsEnabled: Bool,
        featureFlagStore: RemoteFeatureFlagStoreMock = RemoteFeatureFlagStoreMock()
    ) -> RootViewCoordinator {
        RootViewCoordinator(
            featureFlagStore: featureFlagStore,
            windowManager: windowManager,
            app: .wordpress,
            isReaderAndNotificationsEnabled: isReaderAndNotificationsEnabled
        )
    }

    private func postAccountChangeNotification() {
        NotificationCenter.default.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
    }

    private func signInToWordPressDotCom() {
        let account = AccountBuilder(contextManager.mainContext).with(username: "RootViewCoordinatorTests").build()
        UserSettings.defaultDotComUUID = account.uuid
    }
}

private class WindowManagerMock: WindowManager {
    var presentedViewController: UIViewController?
    var didShowUI = false

    override func showUI(for blog: Blog? = nil, animated: Bool = true) {
        didShowUI = true
    }

    override func displayOverlayingWindow(with rootViewController: UIViewController) {
        // The real implementation requires a scene-attached window.
    }

    override func show(
        _ viewController: UIViewController,
        animated: Bool = true,
        completion: WindowManager.Completion? = nil
    ) {
        self.presentedViewController = viewController
        completion?()
    }
}
