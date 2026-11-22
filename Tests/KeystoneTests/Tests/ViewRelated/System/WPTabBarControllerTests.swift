import Testing
import UIKit
import WordPressShared

@testable import WordPress
@testable import WordPressData

@MainActor
@Suite(.serialized)
struct WPTabBarControllerTests {
    @Test func nativeTabsKeepTheExistingDestinations() throws {
        try withController { controller in
            #expect(controller.tabs.map(\.identifier) == ["mysites", "reader", "notifications", "me"])
            #expect(controller.tabs.allSatisfy { $0.preferredPlacement == .fixed })
            #expect(
                controller.tabs.map(\.accessibilityIdentifier) == [
                    "tabbar_mysites", "tabbar_reader", "tabbar_notifications", "tabbar_me"
                ]
            )
            #expect(controller.mode == .tabBar)

            controller.showReaderTab()
            #expect(controller.selectedTab?.viewController === controller.readerNavigationController)
            controller.showNotificationsTab()
            #expect(controller.selectedTab?.viewController === controller.notificationsNavigationController)
            controller.showMeTab()
            #expect(controller.selectedTab?.viewController === controller.meNavigationController)
            controller.showMySitesTab()
            #expect(controller.selectedTab?.viewController === controller.mySitesCoordinator.rootViewController)
        }
    }

    @Test func programmaticSelectionUpdatesMinimization() throws {
        guard #available(iOS 26, *) else { return }
        try withController { controller in
            controller.showReaderTab()
            #expect(controller.tabBarMinimizeBehavior == .onScrollDown)
            controller.showMySitesTab()
            #expect(controller.tabBarMinimizeBehavior == .never)
            controller.selectedTab = try #require(controller.tab(forAppTab: .reader))
            #expect(controller.tabBarMinimizeBehavior == .onScrollDown)
            controller.showMeTab()
            #expect(controller.tabBarMinimizeBehavior == .never)
        }
    }

    @Test func replacingNotificationsPreservesOtherTabsAndTheirStacks() throws {
        try withController { controller in
            let originalTabs = controller.tabs
            let detail = UIViewController()
            controller.readerNavigationController.pushViewController(detail, animated: false)
            controller.showNotificationsTab()

            controller.shouldUseStaticNotifications = false

            #expect(controller.selectedAppTab == .notifications)
            #expect(controller.tabs[2] !== originalTabs[2])
            for index in [0, 1, 3] {
                #expect(controller.tabs[index] === originalTabs[index])
            }
            #expect(controller.readerNavigationController.topViewController === detail)
            #expect(controller.selectedTab?.viewController === controller.notificationsNavigationController)
            #expect(controller.notificationsViewController != nil)
        }
    }

    @Test func signInRebuildsAccountTabsAndSelectsMySite() throws {
        try withController { controller in
            let originalTabs = controller.tabs
            controller.showMeTab()

            NotificationCenter.default.post(
                name: NSNotification.Name(rawValue: WordPressAuthenticationManager.WPSigninDidFinishNotification),
                object: nil
            )

            #expect(controller.selectedAppTab == .mySites)
            #expect(controller.tabs[0] === originalTabs[0])
            for index in [1, 2, 3] {
                #expect(controller.tabs[index] !== originalTabs[index])
            }
            #expect(controller.selectedTab?.viewController === controller.mySitesCoordinator.rootViewController)
        }
    }

    @Test func nativeSelectionTracksAccessWithoutTrackingReselection() throws {
        try withController(staticReader: false) { controller in
            let window = show(controller)
            defer { window.isHidden = true }
            TestAnalyticsTracker.setup()
            defer { TestAnalyticsTracker.tearDown() }
            let reader = try #require(controller.tab(forAppTab: .reader))
            let delegate = try #require(controller.delegate)

            #expect(delegate.tabBarController?(controller, shouldSelectTab: reader) == true)
            #expect(readerAccessCount == 1)

            controller.selectedTab = reader
            #expect(delegate.tabBarController?(controller, shouldSelectTab: reader) == true)
            #expect(readerAccessCount == 1)

            controller.trackTabAccessOnAppDidBecomeActive()
            #expect(readerAccessCount == 2)
        }
    }

    @Test func readerPosterDoesNotTrackReaderAccess() throws {
        try withController { controller in
            let window = show(controller)
            defer { window.isHidden = true }
            TestAnalyticsTracker.setup()
            defer { TestAnalyticsTracker.tearDown() }

            let reader = try #require(controller.tab(forAppTab: .reader))
            #expect(controller.delegate?.tabBarController?(controller, shouldSelectTab: reader) == true)
            controller.selectedTab = reader
            controller.trackTabAccessOnAppDidBecomeActive()
            #expect(readerAccessCount == 0)
        }
    }

    @Test func notificationIndicatorUpdatesTheNativeTab() throws {
        try withController { controller in
            let notifications = try #require(controller.tab(forAppTab: .notifications))
            notifications.image = UIImage(systemName: "pencil")
            notifications.accessibilityLabel = "Pending update"

            controller.updateNotificationBadgeVisibility()
            controller.viewDidAppear(false)

            #expect(notifications.image?.pngData() == UIImage(named: "tab-bar-notifications")?.pngData())
            #expect(notifications.accessibilityLabel == "Notifications")
        }
    }

    @Test func unreadActivityUpdatesTheNativeTabAfterAppearance() throws {
        let defaults = UserPersistentStoreFactory.userDefaultsInstance()
        let key = "welcomeNotificationSeen"
        let original = defaults.object(forKey: key)
        defaults.set(false, forKey: key)
        defer { defaults.set(original, forKey: key) }

        try withController { controller in
            controller.shouldUseStaticNotifications = false
            let notifications = try #require(controller.tab(forAppTab: .notifications))
            controller.viewDidAppear(false)

            let unreadImage = try #require(UIImage(named: "tab-bar-notifications-unread"))
            #expect(notifications.image?.pngData() == unreadImage.pngData())
            #expect(notifications.image?.renderingMode == .alwaysOriginal)
            #expect(notifications.accessibilityLabel == "Notifications Unread")
        }
    }

    @Test func orientationFollowsTheSelectedNativeTab() throws {
        try withController { controller in
            let landscape = UITab(title: "Landscape", image: nil, identifier: "landscape") { _ in
                LandscapeViewController()
            }
            controller.tabs = [landscape]
            controller.selectedTab = landscape
            #expect(controller.supportedInterfaceOrientations == .landscape)
        }
    }

    @Test func tabProvidersDoNotRetainTheTabBarController() throws {
        weak var releasedController: WPTabBarController?
        try autoreleasepool {
            try withController { controller in
                releasedController = controller
                for tab in controller.tabs {
                    _ = tab.viewController
                }
            }
        }
        #expect(releasedController == nil)
    }

    private var readerAccessCount: Int {
        TestAnalyticsTracker.tracked.filter { $0.stat == .readerAccessed }.count
    }

    private func withController(
        staticReader: Bool = true,
        _ body: (WPTabBarController) throws -> Void
    ) throws {
        let original = ContextManager.overrideInstance
        let context = ContextManager.forTesting()
        ContextManager.overrideInstance = context
        defer {
            context.mainContext.reset()
            ContextManager.overrideInstance = original
        }
        try body(WPTabBarController(staticReader: staticReader, staticNotifications: true))
    }

    private func show(_ controller: UIViewController) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.isHidden = false
        window.layoutIfNeeded()
        return window
    }
}

private final class LandscapeViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
}
