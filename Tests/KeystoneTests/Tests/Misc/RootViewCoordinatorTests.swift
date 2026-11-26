import BuildSettingsKit
import Foundation
import XCTest
import WordPressShared

@testable import WordPress
@testable import WordPressData

final class RootViewCoordinatorTests: XCTestCase {
    private var sut: RootViewCoordinator!
    private var windowManager: WindowManagerMock!
    private var contextManager: ContextManager!
    private var savedAppUIType: RootViewCoordinator.AppUIType?
    private var savedIsReaderInWordPressAppEnabled = false

    override func setUp() {
        super.setUp()
        contextManager = ContextManager.forTesting()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        // `RootViewCoordinator` writes the app UI type to a static; restore it so other tests aren't affected.
        savedAppUIType = JetpackFeaturesRemovalCoordinator.currentAppUIType
        savedIsReaderInWordPressAppEnabled = JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled
        windowManager = WindowManagerMock(window: .init())
        sut = RootViewCoordinator(windowManager: windowManager)
    }

    override func tearDown() {
        super.tearDown()
        windowManager = nil
        sut = nil
        contextManager = nil
        UserSettings.defaultDotComUUID = nil
        JetpackFeaturesRemovalCoordinator.currentAppUIType = savedAppUIType
        JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled = savedIsReaderInWordPressAppEnabled
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

    func testStaticScreensWithReaderShowsLiveReaderAndNotificationsPoster() throws {
        let tabBarController = try showTabBar(isReaderInWordPressAppEnabled: true)

        XCTAssertFalse(tabBarController.showsPoster(in: .reader))
        XCTAssertTrue(tabBarController.showsPoster(in: .notifications))
        XCTAssertNotNil(tabBarController.readerPresenter)
        XCTAssertNil(tabBarController.notificationsViewController)
    }

    func testNormalUIShowsLiveReaderAndNotifications() throws {
        // Only apps other than WordPress use the normal UI.
        let tabBarController = try showTabBar(isReaderInWordPressAppEnabled: false, app: .jetpack)

        XCTAssertFalse(tabBarController.showsPoster(in: .reader))
        XCTAssertFalse(tabBarController.showsPoster(in: .notifications))
        XCTAssertNotNil(tabBarController.notificationsViewController)
    }

    func testStaticScreensUIShowsReaderAndNotificationsPosters() throws {
        let tabBarController = try showTabBar(isReaderInWordPressAppEnabled: false)

        XCTAssertTrue(tabBarController.showsPoster(in: .reader))
        XCTAssertTrue(tabBarController.showsPoster(in: .notifications))
        XCTAssertNil(tabBarController.readerPresenter)
        XCTAssertNil(tabBarController.notificationsViewController)
    }

    func testShowNotificationsLandsOnThePosterWithoutRunningTheCompletion() {
        // Given
        let tabBarController = WPTabBarController(staticReader: false, staticNotifications: true)
        var didRunCompletion = false

        // When
        tabBarController.showNotificationsTab { _ in didRunCompletion = true }

        // Then
        XCTAssertEqual(tabBarController.selectedAppTab, .notifications)
        XCTAssertFalse(didRunCompletion)
    }

    func testShowNotificationsPassesTheLiveListToTheCompletion() {
        // Given
        let tabBarController = WPTabBarController(staticScreens: false)
        var receivedList: NotificationsViewController?

        // When
        tabBarController.showNotificationsTab { receivedList = $0 }

        // Then
        XCTAssertEqual(tabBarController.selectedAppTab, .notifications)
        XCTAssertNotNil(receivedList)
        XCTAssertIdentical(receivedList, tabBarController.notificationsViewController)
    }

    func testSettingsRouteOnThePosterDoesNotCrash() {
        // Given
        let tabBarController = WPTabBarController(staticReader: false, staticNotifications: true)
        let presenter: RootViewPresenter = tabBarController

        // When
        presenter.switchNotificationsTabToNotificationSettings()

        // Then
        XCTAssertEqual(tabBarController.selectedAppTab, .notifications)
    }

    func testSignInResolvesStaticScreensWithReaderBeforeTheUIReloads() {
        // Given
        sut = makeCoordinator(isReaderInWordPressAppEnabled: true)
        sut.showAppUI()

        // When
        signInToWordPressDotCom()
        postAccountChangeNotification()

        // Then
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreensWithReader)
        XCTAssertFalse(windowManager.didShowUI)

        // The simplified UI is still shown, so My Site must be able to rebuild it.
        XCTAssertTrue(sut.reloadUIIfNeeded(blog: nil))
        XCTAssertTrue(windowManager.didShowUI)
    }

    func testSignOutRebuildsTheUIOnReload() {
        // Given
        signInToWordPressDotCom()
        sut = makeCoordinator(isReaderInWordPressAppEnabled: true)
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
        sut = makeCoordinator(isReaderInWordPressAppEnabled: false)
        sut.showAppUI()

        // When
        signInToWordPressDotCom()
        postAccountChangeNotification()

        // Then
        XCTAssertTrue(sut.reloadUIIfNeeded(blog: nil))
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreens)
    }

    func testReloadUIWhenSwitchingToStaticScreensWithReader() {
        // Given
        sut = makeCoordinator(isReaderInWordPressAppEnabled: true)
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .simplified)

        // When
        signInToWordPressDotCom()
        let didReload = sut.reloadUIIfNeeded(blog: nil)

        // Then
        XCTAssertTrue(didReload)
        XCTAssertTrue(windowManager.didShowUI)
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreensWithReader)
    }

    func testReloadUIWhenSwitchingFromStaticScreensWithReader() {
        // Given
        signInToWordPressDotCom()
        sut = makeCoordinator(isReaderInWordPressAppEnabled: true)
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreensWithReader)

        // When
        UserSettings.defaultDotComUUID = nil
        let didReload = sut.reloadUIIfNeeded(blog: nil)

        // Then
        XCTAssertTrue(didReload)
        XCTAssertTrue(windowManager.didShowUI)
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .simplified)
    }

    // MARK: - Sign-In

    func testSignInWithTheFlagOnShowsLiveReaderWithoutRelaunch() throws {

        // Given a launch while signed out, with Reader off
        sut = makeCoordinator(isReaderInWordPressAppEnabled: false)
        signInToWordPressDotCom()

        // When the account's flags turn Reader on
        sut.refreshReaderInWordPressAppAfterSignIn(isEnabled: true)
        sut.showAppUI()

        // Then
        let tabBarController = try XCTUnwrap(windowManager.presentedViewController as? WPTabBarController)
        XCTAssertFalse(tabBarController.showsPoster(in: .reader))
        XCTAssertTrue(tabBarController.showsPoster(in: .notifications))
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreensWithReader)
        XCTAssertTrue(JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled)
    }

    func testSignInWithTheFlagOffKeepsTheExistingSignInPath() {
        // Given
        sut = makeCoordinator(isReaderInWordPressAppEnabled: false)
        signInToWordPressDotCom()

        // When
        sut.refreshReaderInWordPressAppAfterSignIn(isEnabled: false)
        sut.showAppUI()

        // Then, as before this change, My Site's reload switches to the static screens with both posters
        XCTAssertFalse(JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled)
        XCTAssertTrue(sut.reloadUIIfNeeded(blog: nil))
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreens)
    }

    func testSignInDoesNotChangeReaderInOtherApps() {
        // Given
        sut = makeCoordinator(isReaderInWordPressAppEnabled: false, app: .jetpack)
        signInToWordPressDotCom()
        let appUIType = JetpackFeaturesRemovalCoordinator.currentAppUIType
        let wasReaderInWordPressAppEnabled = JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled

        // When
        sut.refreshReaderInWordPressAppAfterSignIn(isEnabled: true)

        // Then
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled, wasReaderInWordPressAppEnabled)
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, appUIType)
    }

    func testSignOutAfterAFlagOnSignInRebuildsTheUIOnReload() {
        // Given a sign-in that turned Reader on, which starts observing account changes
        sut = makeCoordinator(isReaderInWordPressAppEnabled: false)
        signInToWordPressDotCom()
        sut.refreshReaderInWordPressAppAfterSignIn(isEnabled: true)
        sut.showAppUI()

        // When
        UserSettings.defaultDotComUUID = nil
        postAccountChangeNotification()

        // Then
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .simplified)
        XCTAssertTrue(sut.reloadUIIfNeeded(blog: nil))
    }

    // MARK: - Helpers

    private func makeCoordinator(
        isReaderInWordPressAppEnabled: Bool,
        app: AppBrand = .wordpress
    ) -> RootViewCoordinator {
        // A real launch reads both values from the same cached flag. Set the shared one too, so tests don't depend
        // on whatever flag value this simulator has cached.
        JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled = isReaderInWordPressAppEnabled
        return RootViewCoordinator(
            windowManager: windowManager,
            app: app,
            isReaderInWordPressAppEnabled: isReaderInWordPressAppEnabled
        )
    }

    /// Signs in and shows the shared app navigation.
    private func showTabBar(
        isReaderInWordPressAppEnabled: Bool,
        app: AppBrand = .wordpress
    ) throws -> WPTabBarController {
        signInToWordPressDotCom()
        sut = makeCoordinator(isReaderInWordPressAppEnabled: isReaderInWordPressAppEnabled, app: app)
        sut.showAppUI()
        return try XCTUnwrap(windowManager.presentedViewController as? WPTabBarController)
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
