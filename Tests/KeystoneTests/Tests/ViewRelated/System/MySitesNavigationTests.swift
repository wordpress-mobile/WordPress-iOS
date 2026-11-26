import Testing
import UIKit
@testable import WordPressData

@testable import WordPress

@MainActor
@Suite(.serialized)
struct MySitesNavigationTests {
    @Test func selectingTheCurrentSitePreservesItsDetail() throws {
        try withSites { coordinator, first, _ in
            coordinator.selectSite(first)
            let detail = UIViewController()
            let content = try #require(coordinator.adaptiveContent)
            content.pushDetail(detail, animated: false)

            coordinator.selectSite(first)

            #expect(coordinator.adaptiveContent === content)
            #expect(content.detailNavigationController.topViewController === detail)
        }
    }

    @Test func selectingAnotherSiteResetsOnlySiteNavigation() throws {
        try withSites { coordinator, first, second in
            coordinator.selectSite(first)
            let root = coordinator.rootViewController
            let previous = try #require(coordinator.adaptiveContent)
            previous.pushDetail(UIViewController(), animated: false)

            coordinator.selectSite(second)

            #expect(coordinator.rootViewController === root)
            #expect(coordinator.currentBlog === second)
            #expect(coordinator.adaptiveContent !== previous)
            #expect(coordinator.navigationController.viewControllers.count == 1)
            #expect(coordinator.navigationController.topViewController is MySiteViewController)
        }
    }

    @Test func siteWithoutDashboardUsesMySiteAsTheList() throws {
        try withSites { coordinator, first, _ in
            JetpackFeaturesRemovalCoordinator.currentAppUIType = .simplified
            coordinator.selectSite(first)
            let content = try #require(coordinator.adaptiveContent)

            #expect(content.listNavigationController === coordinator.navigationController)
            #expect(content.listNavigationController.topViewController is MySiteViewController)
            #expect(content.contentSplitViewController.viewController(for: .compact) == nil)
        }
    }

    @Test func dashboardKeepsNavigationControlsWhileExpanded() throws {
        try withSites { coordinator, first, _ in
            coordinator.selectSite(first)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1180, height: 820))
            window.traitOverrides.horizontalSizeClass = .regular
            window.rootViewController = coordinator.rootViewController
            window.isHidden = false
            window.layoutIfNeeded()
            defer { window.isHidden = true }

            #expect(!coordinator.navigationController.isNavigationBarHidden)

            window.traitOverrides.horizontalSizeClass = .compact
            window.frame.size.width = 390
            window.layoutIfNeeded()
            #expect(coordinator.navigationController.isNavigationBarHidden)

            window.traitOverrides.horizontalSizeClass = .regular
            window.frame.size.width = 1180
            window.layoutIfNeeded()
            #expect(!coordinator.navigationController.isNavigationBarHidden)
        }
    }

    private func withSites(_ body: (MySitesCoordinator, Blog, Blog) throws -> Void) rethrows {
        let originalContext = ContextManager.overrideInstance
        let originalUIType = JetpackFeaturesRemovalCoordinator.currentAppUIType
        let recentSites = UserDefaults.standard.object(forKey: "RecentSites")
        let context = ContextManager.forTesting()
        ContextManager.overrideInstance = context
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .normal
        defer {
            ContextManager.overrideInstance = originalContext
            JetpackFeaturesRemovalCoordinator.currentAppUIType = originalUIType
            UserDefaults.standard.set(recentSites, forKey: "RecentSites")
        }
        let first = BlogBuilder(context.mainContext).with(isHostedAtWPCom: true).withAnAccount().build()
        let second = BlogBuilder(context.mainContext).with(isHostedAtWPCom: true).withAnAccount().build()
        let coordinator = MySitesCoordinator(onBecomeActiveTab: {})
        try body(coordinator, first, second)
    }
}
