import Testing
import UIKit

@testable import WordPress

@MainActor
@Suite(.serialized)
struct AdaptiveNavigationTests {
    @Test func readerDetailSurvivesRepeatedWidthChangesWithoutAnotherFeed() throws {
        let list = UIViewController()
        let feed = UIViewController()
        let article = UIViewController()
        article.hidesBottomBarWhenPushed = true
        let content = AdaptiveListDetailViewController(list: UINavigationController(rootViewController: list))
        var collapseStates: [Bool] = []
        content.onCollapseStateChanged = { collapseStates.append($0) }
        content.showDetail(feed)
        content.pushDetail(article, animated: false)
        let window = show(content, sizeClass: .regular)
        defer { window.isHidden = true }

        for _ in 0..<2 {
            resize(window, to: .compact)
            #expect(content.contentSplitViewController.isCollapsed)
            #expect(content.detailNavigationController.topViewController === article)
            #expect(content.requestsHiddenBottomBar)
            resize(window, to: .regular)
            #expect(!content.contentSplitViewController.isCollapsed)
            #expect(content.detailNavigationController.viewControllers.count == 2)
            #expect(content.detailNavigationController.viewControllers.first === feed)
            #expect(content.detailNavigationController.topViewController === article)
        }

        #expect(Array(collapseStates.suffix(4)) == [true, false, true, false])
        content.detailNavigationController.popViewController(animated: false)
        #expect(content.detailNavigationController.topViewController === feed)
        #expect(!content.requestsHiddenBottomBar)
    }

    @Test func detailOpenedWhileCompactSurvivesExpansionAndBack() async throws {
        let list = UIViewController()
        let feed = UIViewController()
        let article = UIViewController()
        article.hidesBottomBarWhenPushed = true
        let content = AdaptiveListDetailViewController(list: UINavigationController(rootViewController: list))
        // iOS 18 needs a scene-backed window to complete the collapsed navigation lifecycle.
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.traitOverrides.horizontalSizeClass = .compact
        window.rootViewController = content
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        try await Task.sleep(for: .milliseconds(200))

        content.showDetail(feed)
        try await Task.sleep(for: .milliseconds(700))
        content.pushDetail(article, animated: false)
        try await Task.sleep(for: .milliseconds(700))
        #expect(content.detailNavigationController.topViewController === article)
        resize(window, to: .regular)
        try await Task.sleep(for: .milliseconds(200))
        #expect(content.detailNavigationController.viewControllers == [feed, article])
        #expect(content.isListVisible)

        resize(window, to: .compact)
        content.detailNavigationController.popViewController(animated: false)
        #expect(content.detailNavigationController.topViewController === feed)
        #expect(!content.requestsHiddenBottomBar)
        content.show(.primary)
        try await Task.sleep(for: .milliseconds(700))
        window.layoutIfNeeded()
        #expect(content.listNavigationController.topViewController === list)
    }

    @Test func compactMySiteBackReturnsToTheSameDashboard() {
        let menu = UIViewController()
        let dashboard = UIViewController()
        let stats = UIViewController()
        let navigation = UINavigationController(rootViewController: dashboard)
        let content = AdaptiveListDetailViewController(
            list: UINavigationController(rootViewController: menu),
            detail: navigation,
            usesDetailForCompactWidth: true
        )
        let window = show(content, sizeClass: .regular)
        defer { window.isHidden = true }
        content.pushDetail(stats, animated: false)

        resize(window, to: .compact)
        #expect(content.contentSplitViewController.viewController(for: .compact) === navigation)
        #expect(navigation.topViewController === stats)
        navigation.popViewController(animated: false)
        #expect(navigation.topViewController === dashboard)
        #expect(navigation.viewControllers.count == 1)
        #expect(!content.isListVisible)

        resize(window, to: .regular)
        #expect(content.isListVisible)
        #expect(navigation.topViewController === dashboard)
    }

    @Test func mySiteCompactColumnKeepsTheDestinationNavigationBar() async throws {
        let navigation = UINavigationController(rootViewController: UIViewController())
        let content = AdaptiveListDetailViewController(
            list: UINavigationController(rootViewController: UIViewController()),
            detail: navigation,
            usesDetailForCompactWidth: true
        )
        let tabs = UITabBarController()
        tabs.mode = .tabSidebar
        tabs.tabs = [UITab(title: "My Site", image: nil, identifier: "site") { _ in content }]
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.traitOverrides.horizontalSizeClass = .regular
        window.rootViewController = tabs
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        try await Task.sleep(for: .milliseconds(200))
        let posts = UIViewController()
        posts.title = "Posts"
        navigation.pushViewController(posts, animated: false)

        resize(window, to: .compact)
        try await Task.sleep(for: .milliseconds(200))

        #expect(navigation.topViewController === posts)
        #expect(navigation.parent === content)
        #expect(!navigation.isNavigationBarHidden)
        navigation.popViewController(animated: false)
        #expect(navigation.viewControllers.count == 1)
    }

    @Test func selectingAnotherMenuItemKeepsOnlyDashboardUnderIt() {
        let dashboard = UIViewController()
        let posts = UIViewController()
        let editor = UIViewController()
        let pages = UIViewController()
        let content = AdaptiveListDetailViewController(
            list: UINavigationController(rootViewController: UIViewController()),
            detail: UINavigationController(rootViewController: dashboard),
            usesDetailForCompactWidth: true
        )
        content.showDetail(posts, keeping: dashboard)
        content.pushDetail(editor, animated: false)
        content.showDetail(pages, keeping: dashboard)

        #expect(content.detailNavigationController.viewControllers == [dashboard, pages])
    }

    @Test func anUnselectedNotificationListStaysTheCompactLandingScreen() {
        let list = UIViewController()
        let navigation = UINavigationController(rootViewController: list)
        let content = AdaptiveListDetailViewController(list: navigation)
        let window = show(content, sizeClass: .regular)
        defer { window.isHidden = true }

        resize(window, to: .compact)
        #expect(navigation.topViewController === list)
        #expect(!content.requestsHiddenBottomBar)
    }

    @Test func returningToTheCompactListRestoresTheTabBar() {
        let list = UIViewController()
        let detail = UIViewController()
        detail.hidesBottomBarWhenPushed = true
        let navigation = UINavigationController(rootViewController: list)
        let content = AdaptiveListDetailViewController(list: navigation)
        content.showDetail(detail)
        let window = show(content, sizeClass: .regular)
        defer { window.isHidden = true }

        resize(window, to: .compact)
        #expect(content.requestsHiddenBottomBar)
        content.contentSplitViewController.show(.primary)
        window.layoutIfNeeded()
        #expect(navigation.topViewController === list)
        #expect(!content.requestsHiddenBottomBar)

        resize(window, to: .regular)
        #expect(content.detailNavigationController.topViewController === detail)
        #expect(content.isListVisible)
    }

    @Test func offscreenContentRetainsItsDetailWhenTheSelectedTabResizes() {
        let list = UIViewController()
        let article = UIViewController()
        let content = AdaptiveListDetailViewController(list: UINavigationController(rootViewController: list))
        content.showDetail(article)
        let tabs = UITabBarController()
        tabs.mode = .tabSidebar
        let reader = UITab(title: "Reader", image: nil, identifier: "reader") { _ in content }
        let other = UITab(title: "Other", image: nil, identifier: "other") { _ in UIViewController() }
        tabs.tabs = [reader, other]
        let window = show(tabs, sizeClass: .regular)
        defer { window.isHidden = true }

        tabs.selectedTab = other
        resize(window, to: .compact)
        resize(window, to: .regular)
        tabs.selectedTab = reader
        window.layoutIfNeeded()

        #expect(content.detailNavigationController.topViewController === article)
        #expect(content.detailNavigationController.viewControllers.count == 1)
        #expect(content.listNavigationController.splitViewController === content)
    }

    @Test func navigationBarsKeepTheirPositionAfterInactiveResizing() async throws {
        let notifications = AdaptiveListDetailViewController(
            list: UINavigationController(rootViewController: UIViewController())
        )
        let reader = AdaptiveListDetailViewController(
            list: UINavigationController(rootViewController: UIViewController())
        )
        for content in [notifications, reader] {
            let article = UIViewController()
            article.hidesBottomBarWhenPushed = true
            article.navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .action)
            content.showDetail(article)
        }
        var returnsToList = 0
        notifications.onReturnToList = { returnsToList += 1 }
        let tabs = UITabBarController()
        tabs.mode = .tabSidebar
        let notificationTab = UITab(title: "Notifications", image: nil, identifier: "notifications") { _ in
            notifications
        }
        let readerTab = UITab(title: "Reader", image: nil, identifier: "reader") { _ in reader }
        tabs.tabs = [notificationTab, readerTab]
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.traitOverrides.horizontalSizeClass = .regular
        window.rootViewController = tabs
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(200))
        window.layoutIfNeeded()
        defer { window.isHidden = true }
        // Compare the same width and visible column before and after the round trip.
        resize(window, to: .regular)
        if !notifications.isCollapsed {
            notifications.show(.primary)
        }
        try await Task.sleep(for: .milliseconds(200))
        window.layoutIfNeeded()
        let before = notifications.listNavigationController.navigationBar.convert(CGPoint.zero, to: window)

        tabs.selectedTab = readerTab
        try await Task.sleep(for: .milliseconds(100))
        resize(window, to: .compact)
        try await Task.sleep(for: .milliseconds(100))
        tabs.setTabBarHidden(true, animated: false)
        tabs.selectedTab = notificationTab
        try await Task.sleep(for: .milliseconds(100))
        #expect(returnsToList == 0)
        notifications.listNavigationController.popViewController(animated: true)
        try await Task.sleep(for: .milliseconds(700))
        #expect(returnsToList == 1)
        tabs.setTabBarHidden(false, animated: false)
        tabs.selectedTab = readerTab
        try await Task.sleep(for: .milliseconds(100))
        tabs.setTabBarHidden(true, animated: false)
        resize(window, to: .regular)
        try await Task.sleep(for: .milliseconds(100))
        tabs.setTabBarHidden(false, animated: false)
        tabs.selectedTab = notificationTab
        try await Task.sleep(for: .milliseconds(100))
        window.layoutIfNeeded()

        if !notifications.isCollapsed {
            notifications.show(.primary)
        }
        try await Task.sleep(for: .milliseconds(200))
        window.layoutIfNeeded()
        let after = notifications.listNavigationController.navigationBar.convert(CGPoint.zero, to: window)
        #expect(before.y > 0)
        #expect(after.y == before.y)
        #expect(returnsToList == 1)
    }

    private func show(_ controller: UIViewController, sizeClass: UIUserInterfaceSizeClass) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1180, height: 820))
        window.traitOverrides.horizontalSizeClass = sizeClass
        window.rootViewController = controller
        window.isHidden = false
        window.layoutIfNeeded()
        return window
    }

    private func resize(_ window: UIWindow, to sizeClass: UIUserInterfaceSizeClass) {
        window.traitOverrides.horizontalSizeClass = sizeClass
        window.frame.size.width = sizeClass == .compact ? 390 : 1180
        window.setNeedsLayout()
        window.layoutIfNeeded()
        window.rootViewController?.view.layoutIfNeeded()
    }
}
