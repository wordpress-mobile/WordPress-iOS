import Foundation
import XCTest
import WordPressShared

@testable import WordPress
@testable import WordPressData

final class RootViewCoordinatorTests: XCTestCase {
    private var sut: RootViewCoordinator!
    private var windowManager: WindowManagerMock!
    private var contextManager: ContextManager!
    private var wasReaderInWordPressAppEnabled = false

    override func setUp() {
        super.setUp()
        wasReaderInWordPressAppEnabled = JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled
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
        JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled = wasReaderInWordPressAppEnabled
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
        let tabBarController = try showTabBar(
            isReaderInWordPressAppEnabled: true,
            featureFlagStore: makeProductionFlagStore()
        )

        XCTAssertFalse(tabBarController.showsPoster(in: .reader))
        XCTAssertTrue(tabBarController.showsPoster(in: .notifications))
        XCTAssertNotNil(tabBarController.readerPresenter)
        XCTAssertNil(tabBarController.notificationsViewController)
    }

    func testNormalUIShowsLiveReaderAndNotifications() throws {
        let tabBarController = try showTabBar(isReaderInWordPressAppEnabled: false)

        XCTAssertFalse(tabBarController.showsPoster(in: .reader))
        XCTAssertFalse(tabBarController.showsPoster(in: .notifications))
        XCTAssertNotNil(tabBarController.notificationsViewController)
    }

    func testStaticScreensUIShowsReaderAndNotificationsPosters() throws {
        let tabBarController = try showTabBar(
            isReaderInWordPressAppEnabled: false,
            featureFlagStore: makeFreshInstallFlagStore()
        )

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
        sut = makeCoordinator(isReaderInWordPressAppEnabled: true, featureFlagStore: makeProductionFlagStore())
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
        sut = makeCoordinator(isReaderInWordPressAppEnabled: true, featureFlagStore: makeProductionFlagStore())
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
        sut = makeCoordinator(isReaderInWordPressAppEnabled: false, featureFlagStore: makeFreshInstallFlagStore())
        sut.showAppUI()

        // When
        signInToWordPressDotCom()
        postAccountChangeNotification()

        // Then
        XCTAssertTrue(sut.reloadUIIfNeeded(blog: nil))
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreens)
    }

    func testReloadUIWhenSwitchingToStaticScreensWithReader() {
        // Given a fresh install, which resolves the normal type until the remote flags arrive
        sut = makeCoordinator(isReaderInWordPressAppEnabled: true, featureFlagStore: makeFreshInstallFlagStore())
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .normal)

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
        sut = makeCoordinator(isReaderInWordPressAppEnabled: true, featureFlagStore: makeFreshInstallFlagStore())
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreensWithReader)

        // When
        UserSettings.defaultDotComUUID = nil
        let didReload = sut.reloadUIIfNeeded(blog: nil)

        // Then
        XCTAssertTrue(didReload)
        XCTAssertTrue(windowManager.didShowUI)
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .normal)
    }

    // MARK: - Reader flag fetched after launch

    func testReaderFlagTurningOnAfterLaunchRebuildsTheUIWithoutARelaunch() throws {
        try XCTSkipIf(UIDevice.isPad(), "The iPad split view applies the type in place")

        // Given a WordPress.com account whose first launch had no cached flag
        signInToWordPressDotCom()
        let featureFlagStore = makeProductionFlagStore()
        sut = makeCoordinator(isReaderInWordPressAppEnabled: false, featureFlagStore: featureFlagStore)
        sut.showAppUI()
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreens)

        // When the fetch brings the flag
        featureFlagStore.enabledFeatureFlags.insert(RemoteFeatureFlag.readerInWordPressApp.remoteKey)
        sut.remoteFeatureFlagsDidUpdate()

        // Then the UI and the Notifications scope change together
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreensWithReader)
        XCTAssertTrue(windowManager.didShowUI)
        XCTAssertTrue(JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled)
        XCTAssertEqual(NotificationsListScope.forAppNavigation(app: .wordpress), .reader)
    }

    func testReaderFlagTurningOffAfterLaunchRebuildsTheUIWithoutARelaunch() throws {
        try XCTSkipIf(UIDevice.isPad(), "The iPad split view applies the type in place")

        // Given
        signInToWordPressDotCom()
        let featureFlagStore = makeProductionFlagStore()
        sut = makeCoordinator(isReaderInWordPressAppEnabled: true, featureFlagStore: featureFlagStore)
        sut.showAppUI()
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreensWithReader)

        // When
        featureFlagStore.disabledFeatureFlag.insert(RemoteFeatureFlag.readerInWordPressApp.remoteKey)
        sut.remoteFeatureFlagsDidUpdate()

        // Then
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreens)
        XCTAssertTrue(windowManager.didShowUI)
        XCTAssertFalse(JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled)
        XCTAssertEqual(NotificationsListScope.forAppNavigation(app: .wordpress), .all)
    }

    func testUnchangedReaderFlagLeavesTheUIAlone() {
        // Given
        signInToWordPressDotCom()
        let featureFlagStore = makeProductionFlagStore()
        featureFlagStore.disabledFeatureFlag.insert(RemoteFeatureFlag.readerInWordPressApp.remoteKey)
        sut = makeCoordinator(isReaderInWordPressAppEnabled: false, featureFlagStore: featureFlagStore)
        sut.showAppUI()

        // When
        sut.remoteFeatureFlagsDidUpdate()

        // Then
        XCTAssertFalse(windowManager.didShowUI)
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreens)
    }

    func testReaderFlagFetchedOnTheSignInScreenAppliesToTheNextSignIn() {
        // Given a fresh install on the sign-in screen
        let featureFlagStore = makeFreshInstallFlagStore()
        sut = makeCoordinator(isReaderInWordPressAppEnabled: false, featureFlagStore: featureFlagStore)
        sut.showSignInUI()

        // When the launch fetch brings the flag
        featureFlagStore.enabledFeatureFlags.insert(RemoteFeatureFlag.readerInWordPressApp.remoteKey)
        NotificationCenter.default.post(name: RemoteFeatureFlagStore.didUpdateNotification, object: nil)

        // Then nothing is shown yet
        XCTAssertFalse(windowManager.didShowUI)
        XCTAssertTrue(JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled)

        // And signing in resolves the type with the flag, through the account-change observer that
        // a launch without the flag used to skip
        signInToWordPressDotCom()
        postAccountChangeNotification()
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreensWithReader)
    }

    func testReaderFlagDoesNotChangeJetpack() {
        // Given
        let featureFlagStore = makeProductionFlagStore()
        sut = RootViewCoordinator(
            featureFlagStore: featureFlagStore,
            windowManager: windowManager,
            app: .jetpack,
            isReaderInWordPressAppEnabled: false
        )
        sut.showAppUI()
        let wasReaderInWordPressAppEnabled = JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled

        // When
        featureFlagStore.enabledFeatureFlags.insert(RemoteFeatureFlag.readerInWordPressApp.remoteKey)
        sut.remoteFeatureFlagsDidUpdate()

        // Then
        XCTAssertFalse(windowManager.didShowUI)
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled, wasReaderInWordPressAppEnabled)
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .normal)
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

    func testSplitViewCompactTabBarFollowsTheAppUIType() throws {
        // The compact tab bar shows what the iPhone shows, so narrowing the window can't get
        // around the Jetpack features removal.
        let expectations: [(RootViewCoordinator.AppUIType, liveReader: Bool, liveNotifications: Bool)] = [
            (.normal, liveReader: true, liveNotifications: true),
            (.staticScreensWithReader, liveReader: true, liveNotifications: false),
            (.staticScreens, liveReader: false, liveNotifications: false),
            (.simplified, liveReader: false, liveNotifications: false)
        ]
        for (appUIType, liveReader, liveNotifications) in expectations {
            JetpackFeaturesRemovalCoordinator.currentAppUIType = appUIType
            let tabBar = try XCTUnwrap(compactTabBar(of: SplitViewRootPresenter()))
            XCTAssertEqual(tabBar.showsPoster(in: .reader), !liveReader, "Reader in \(appUIType)")
            XCTAssertEqual(tabBar.showsPoster(in: .notifications), !liveNotifications, "Notifications in \(appUIType)")
            XCTAssertEqual(tabBar.readerPresenter != nil, liveReader, "Reader presenter in \(appUIType)")
            XCTAssertEqual(tabBar.notificationsViewController != nil, liveNotifications, "list in \(appUIType)")
        }
    }

    func testSplitViewCompactTabBarShowsPostersWhenTheAppUITypeTurnsOffJetpackFeatures() throws {
        // Given
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .normal
        let presenter = SplitViewRootPresenter()
        let tabBar = try XCTUnwrap(compactTabBar(of: presenter))
        tabBar.selectedIndex = WPTab.reader.rawValue
        let tabs = tabBar.viewControllers ?? []

        // When
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreens
        presenter.appUITypeDidChange()

        // Then
        XCTAssertTrue(tabBar.showsPoster(in: .reader))
        XCTAssertTrue(tabBar.readerNavigationController.viewControllers.first is MovedToJetpackViewController)
        XCTAssertNil(tabBar.readerPresenter)
        XCTAssertTrue(tabBar.showsPoster(in: .notifications))
        XCTAssertNil(tabBar.notificationsViewController)
        XCTAssertEqual(tabBar.selectedIndex, WPTab.reader.rawValue)
        XCTAssertTrue(zip(tabs, tabBar.viewControllers ?? []).allSatisfy { $0 === $1 })
    }

    func testSplitViewShowReaderInStaticScreensPresentsThePoster() throws {
        // Given
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreens
        let presenter = SplitViewRootPresenter()
        try showExpanded(presenter)

        // When a Reader link arrives
        presenter.showReader(path: .discover)

        // Then
        XCTAssertNotEqual(presenter.currentlySelectedScreen(), WPTabBarCurrentlySelectedScreenReader)
        let sheet = try XCTUnwrap(presenter.rootViewController.presentedViewController as? UINavigationController)
        XCTAssertTrue(sheet.viewControllers.first is MovedToJetpackViewController)
    }

    func testSplitViewShowReaderInStaticScreensWithReaderSelectsReader() throws {
        // Given
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreensWithReader
        let presenter = SplitViewRootPresenter()
        try showExpanded(presenter)

        // When
        presenter.showReader(path: nil)

        // Then
        XCTAssertEqual(presenter.currentlySelectedScreen(), WPTabBarCurrentlySelectedScreenReader)
        XCTAssertNil(presenter.rootViewController.presentedViewController)
    }

    func testSplitViewShowNotificationsInStaticScreensPresentsThePoster() throws {
        // Given
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreens
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

    func testSplitViewCompactTabBarShowsThePosterWhenAnAccountChangeTurnsOnStaticScreensWithReader() throws {
        // Given a split view built before a WordPress.com account exists, on the Notifications tab
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .normal
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

        // When signing out resolves the normal type
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .normal
        presenter.appUITypeDidChange()

        // Then
        XCTAssertFalse(tabBar.showsPoster(in: .notifications))
        XCTAssertNotNil(tabBar.notificationsViewController)
    }

    func testSplitViewCompactTabBarShowsPostersWhenSignOutResolvesSimplified() throws {
        // Given
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreensWithReader
        let presenter = SplitViewRootPresenter()
        let tabBar = try XCTUnwrap(compactTabBar(of: presenter))

        // When signing out with the self-hosted removal phase on
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .simplified
        presenter.appUITypeDidChange()

        // Then, as on the iPhone, where the simplified UI has neither tab
        XCTAssertTrue(tabBar.showsPoster(in: .reader))
        XCTAssertTrue(tabBar.showsPoster(in: .notifications))
    }

    func testTabsKeepTheirNavigationControllersWhenTheAccountOrAppUIChanges() {
        // Given
        signInToWordPressDotCom()
        let tabBarController = WPTabBarController(staticScreens: false)
        let tabs = tabBarController.viewControllers ?? []
        let tabBarItems = tabs.map(\.tabBarItem)

        // When
        postSignInFinishedNotification()
        UserSettings.defaultDotComUUID = nil
        postAccountChangeNotification()
        tabBarController.shouldUseStaticNotifications = true

        // Then
        let tabsAfter = tabBarController.viewControllers ?? []
        XCTAssertEqual(tabsAfter.count, 4)
        XCTAssertTrue(zip(tabs, tabsAfter).allSatisfy { $0 === $1 })
        XCTAssertTrue(zip(tabBarItems, tabsAfter.map(\.tabBarItem)).allSatisfy { $0 === $1 })
    }

    func testAccountChangeWithAnAccountKeepsTheReaderTabWorking() throws {
        // Given
        let account = signInToWordPressDotCom()
        let tabBarController = WPTabBarController(staticScreens: false)

        // When the default account is posted again, as when the same account signs in again
        NotificationCenter.default.post(name: .wpAccountDefaultWordPressComAccountChanged, object: account)

        // Then the Reader tab shows the screen of a presenter that is still alive
        let readerPresenter = try XCTUnwrap(tabBarController.readerPresenter)
        XCTAssertIdentical(tabBarController.readerNavigationController.viewControllers.first, readerPresenter.sidebar)
    }

    func testSignOutShowsTheLoggedOutReaderInTheSameTab() {
        // Given
        signInToWordPressDotCom()
        let tabBarController = WPTabBarController(staticScreens: false)
        let readerNavigationController = tabBarController.readerNavigationController

        // When
        UserSettings.defaultDotComUUID = nil
        postAccountChangeNotification()

        // Then
        XCTAssertIdentical(tabBarController.readerNavigationController, readerNavigationController)
        XCTAssertEqual(readerNavigationController.viewControllers.count, 1)
        XCTAssertTrue(readerNavigationController.viewControllers.first is ReaderLoggedOutViewController)
    }

    func testStaticNotificationsSwapsTheFirstScreenAndKeepsTheSelectedTab() {
        // Given
        let tabBarController = WPTabBarController(staticScreens: false)
        tabBarController.selectedIndex = WPTab.notifications.rawValue
        let notificationsNavigationController = tabBarController.notificationsNavigationController

        // When
        tabBarController.shouldUseStaticNotifications = true

        // Then
        XCTAssertEqual(tabBarController.selectedIndex, WPTab.notifications.rawValue)
        XCTAssertNil(tabBarController.notificationsViewController)
        XCTAssertEqual(notificationsNavigationController.viewControllers.count, 1)
        XCTAssertTrue(notificationsNavigationController.viewControllers.first is MovedToJetpackViewController)
    }

    func testSidebarDoesNotRestoreTheReaderWhenItIsUnavailable() {
        // Given a Reader selection saved while the Reader was available
        let wasReaderSelected = UserDefaults.standard.isReaderSelected
        addTeardownBlock { UserDefaults.standard.isReaderSelected = wasReaderSelected }
        UserDefaults.standard.isReaderSelected = true

        // When the sidebar is built for an app UI type without the Reader
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreens
        let staticScreensViewModel = SidebarViewModel(contextManager: contextManager)

        // Then
        XCTAssertNotEqual(staticScreensViewModel.selection, .reader)

        // And the Reader is still restored where it is available
        UserDefaults.standard.isReaderSelected = true
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreensWithReader
        XCTAssertEqual(SidebarViewModel(contextManager: contextManager).selection, .reader)
    }

    func testStaticReaderSwapsTheFirstScreenAndKeepsTheSelectedTab() {
        // Given
        signInToWordPressDotCom()
        let tabBarController = WPTabBarController(staticScreens: false)
        tabBarController.selectedIndex = WPTab.reader.rawValue
        let readerNavigationController = tabBarController.readerNavigationController

        // When
        tabBarController.shouldUseStaticReader = true

        // Then
        XCTAssertIdentical(tabBarController.readerNavigationController, readerNavigationController)
        XCTAssertEqual(readerNavigationController.viewControllers.count, 1)
        XCTAssertTrue(readerNavigationController.viewControllers.first is MovedToJetpackViewController)
        XCTAssertNil(tabBarController.readerPresenter)
        XCTAssertEqual(tabBarController.selectedIndex, WPTab.reader.rawValue)

        // And back
        tabBarController.shouldUseStaticReader = false
        XCTAssertIdentical(readerNavigationController.viewControllers.first, tabBarController.readerPresenter?.sidebar)
    }

    // MARK: - Helpers

    /// The removal phase flags in production: a WordPress.com account resolves to static screens,
    /// and no account to the self-hosted phase.
    private func makeProductionFlagStore() -> RemoteFeatureFlagStoreMock {
        let featureFlagStore = makeFreshInstallFlagStore()
        featureFlagStore.removalPhaseSelfHosted = true
        return featureFlagStore
    }

    /// The removal phase flags before the remote values are cached: only the static posters flag
    /// defaults to true, so a launch without an account resolves the normal type.
    private func makeFreshInstallFlagStore() -> RemoteFeatureFlagStoreMock {
        let featureFlagStore = RemoteFeatureFlagStoreMock()
        featureFlagStore.removalPhaseStaticScreens = true
        return featureFlagStore
    }

    private func makeCoordinator(
        isReaderInWordPressAppEnabled: Bool,
        featureFlagStore: RemoteFeatureFlagStoreMock
    ) -> RootViewCoordinator {
        RootViewCoordinator(
            featureFlagStore: featureFlagStore,
            windowManager: windowManager,
            app: .wordpress,
            isReaderInWordPressAppEnabled: isReaderInWordPressAppEnabled
        )
    }

    /// Signs in and shows the app UI on the phone presenter.
    private func showTabBar(
        isReaderInWordPressAppEnabled: Bool,
        featureFlagStore: RemoteFeatureFlagStoreMock = RemoteFeatureFlagStoreMock()
    ) throws -> WPTabBarController {
        try XCTSkipIf(UIDevice.isPad(), "The iPad presenter ignores the app UI type")
        signInToWordPressDotCom()
        sut = makeCoordinator(
            isReaderInWordPressAppEnabled: isReaderInWordPressAppEnabled,
            featureFlagStore: featureFlagStore
        )
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

    @discardableResult
    private func signInToWordPressDotCom() -> WPAccount {
        let account = AccountBuilder(contextManager.mainContext).with(username: "RootViewCoordinatorTests").build()
        UserSettings.defaultDotComUUID = account.uuid
        return account
    }

    private func postSignInFinishedNotification() {
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: WordPressAuthenticationManager.WPSigninDidFinishNotification),
            object: nil
        )
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
