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

    override func setUp() {
        super.setUp()
        contextManager = ContextManager.forTesting()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        // `RootViewCoordinator` writes the app UI type to a static; restore it so other tests aren't affected.
        savedAppUIType = JetpackFeaturesRemovalCoordinator.currentAppUIType
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
        XCTAssertEqual(tabBarController.selectedIndex, WPTab.notifications.rawValue)
        XCTAssertFalse(didRunCompletion)
    }

    func testShowNotificationsPassesTheLiveListToTheCompletion() {
        // Given
        let tabBarController = WPTabBarController(staticScreens: false)
        var receivedList: NotificationsViewController?

        // When
        tabBarController.showNotificationsTab { receivedList = $0 }

        // Then
        XCTAssertEqual(tabBarController.selectedIndex, WPTab.notifications.rawValue)
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
        XCTAssertEqual(tabBarController.selectedIndex, WPTab.notifications.rawValue)
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

    func testSplitViewShowNotificationsInStaticScreensWithReaderPresentsThePoster() throws {
        // Given
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreensWithReader
        let presenter = SplitViewRootPresenter()
        try showExpanded(presenter)
        var didRunCompletion = false

        // When
        presenter.showNotificationsTab { _ in didRunCompletion = true }

        // Then
        XCTAssertFalse(didRunCompletion)
        XCTAssertNotEqual(presenter.currentlySelectedScreen(), WPTabBarCurrentlySelectedScreenNotifications)
        let sheet = try XCTUnwrap(presenter.rootViewController.presentedViewController as? UINavigationController)
        XCTAssertTrue(sheet.viewControllers.first is MovedToJetpackViewController)
    }

    func testSplitViewShowNotificationsAgainInStaticScreensWithReaderKeepsOnePoster() throws {
        // Given
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreensWithReader
        let presenter = SplitViewRootPresenter()
        try showExpanded(presenter)
        presenter.showNotificationsTab(completion: nil)
        let poster = try XCTUnwrap(presenter.rootViewController.presentedViewController)
        // UIKit refuses to present while another presentation is in progress, which would hide
        // a second poster. Wait until the first one is on screen.
        let appeared = NSPredicate { _, _ in poster.viewIfLoaded?.window != nil && !poster.isBeingPresented }
        wait(for: [expectation(for: appeared, evaluatedWith: nil)], timeout: 5)

        // When
        presenter.showNotificationsTab(completion: nil)

        // Then
        XCTAssertNil(poster.presentedViewController)
    }

    func testSplitViewShowNotificationsInNormalUISelectsNotifications() throws {
        // Given
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .normal
        let presenter = SplitViewRootPresenter()
        try showExpanded(presenter)
        var receivedList: NotificationsViewController?

        // When
        presenter.showNotificationsTab { receivedList = $0 }

        // Then
        XCTAssertNotNil(receivedList)
        XCTAssertEqual(presenter.currentlySelectedScreen(), WPTabBarCurrentlySelectedScreenNotifications)
    }

    func testSplitViewCompactTabBarFollowsStaticScreensWithReader() throws {
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreensWithReader
        let withReaderPresenter = SplitViewRootPresenter()
        let withReaderTabBar = try XCTUnwrap(compactTabBar(of: withReaderPresenter))
        XCTAssertFalse(withReaderTabBar.showsPoster(in: .reader))
        XCTAssertTrue(withReaderTabBar.showsPoster(in: .notifications))

        // Outside `staticScreensWithReader` the compact tab bar keeps its live tabs.
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreens
        let staticScreensPresenter = SplitViewRootPresenter()
        let staticScreensTabBar = try XCTUnwrap(compactTabBar(of: staticScreensPresenter))
        XCTAssertFalse(staticScreensTabBar.showsPoster(in: .reader))
        XCTAssertFalse(staticScreensTabBar.showsPoster(in: .notifications))
    }

    func testSplitViewCompactTabBarShowsThePosterWhenAnAccountChangeTurnsOnStaticScreensWithReader() throws {
        // Given a split view built before a WordPress.com account exists, on the Notifications tab
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .simplified
        let presenter = SplitViewRootPresenter()
        let tabBar = try XCTUnwrap(compactTabBar(of: presenter))
        tabBar.selectedIndex = WPTab.notifications.rawValue
        XCTAssertNotNil(tabBar.notificationsViewController)

        // When signing in from the sidebar sets the account, even if the site sync then fails and
        // the sign-in never completes
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreensWithReader
        presenter.appUITypeDidChange()

        // Then
        XCTAssertTrue(tabBar.showsPoster(in: .notifications))
        XCTAssertNil(tabBar.notificationsViewController)
        XCTAssertFalse(tabBar.showsPoster(in: .reader))
        XCTAssertEqual(tabBar.selectedIndex, WPTab.notifications.rawValue)

        // And a completed sign-in, which rebuilds every tab, keeps the poster
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: WordPressAuthenticationManager.WPSigninDidFinishNotification),
            object: nil
        )
        XCTAssertTrue(tabBar.showsPoster(in: .notifications))
        XCTAssertNil(tabBar.notificationsViewController)
    }

    func testSplitViewCompactTabBarRestoresTheLiveListWhenSignOutLeavesStaticScreensWithReader() throws {
        // Given
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreensWithReader
        let presenter = SplitViewRootPresenter()
        let tabBar = try XCTUnwrap(compactTabBar(of: presenter))
        XCTAssertTrue(tabBar.showsPoster(in: .notifications))

        // When
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .simplified
        presenter.appUITypeDidChange()

        // Then the compact layout's live tabs return, as before `staticScreensWithReader`
        XCTAssertFalse(tabBar.showsPoster(in: .notifications))
        XCTAssertNotNil(tabBar.notificationsViewController)
    }

    // MARK: - Helpers

    private func makeCoordinator(
        isReaderInWordPressAppEnabled: Bool,
        app: AppBrand = .wordpress
    ) -> RootViewCoordinator {
        RootViewCoordinator(
            windowManager: windowManager,
            app: app,
            isReaderInWordPressAppEnabled: isReaderInWordPressAppEnabled
        )
    }

    /// Signs in and shows the app UI on the phone presenter.
    private func showTabBar(
        isReaderInWordPressAppEnabled: Bool,
        app: AppBrand = .wordpress
    ) throws -> WPTabBarController {
        try XCTSkipIf(UIDevice.isPad(), "The iPad presenter ignores the app UI type")
        signInToWordPressDotCom()
        sut = makeCoordinator(isReaderInWordPressAppEnabled: isReaderInWordPressAppEnabled, app: app)
        sut.showAppUI()
        return try XCTUnwrap(windowManager.presentedViewController as? WPTabBarController)
    }

    /// Shows the presenter in a regular-width window, so that its split view isn't collapsed.
    private func showExpanded(_ presenter: SplitViewRootPresenter) throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1366, height: 1024))
        window.traitOverrides.horizontalSizeClass = .regular
        window.rootViewController = presenter.rootViewController
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        window.layoutIfNeeded()
        let splitVC = try XCTUnwrap(presenter.rootViewController as? UISplitViewController)
        try XCTSkipIf(splitVC.isCollapsed, "The split view can't expand in this test environment")
    }

    private func compactTabBar(of presenter: SplitViewRootPresenter) -> WPTabBarController? {
        (presenter.rootViewController as? UISplitViewController)?.viewController(for: .compact) as? WPTabBarController
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
