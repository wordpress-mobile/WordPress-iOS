import Testing
import UIKit
import Support

@testable import WordPress
@testable import WordPressData

@MainActor
@Suite(.serialized)
struct AppSidebarTests {
    @Test func accountToolsAreActionsRatherThanContentTabs() throws {
        try withContext { _ in
            let controller = WPTabBarController(staticReader: true, staticNotifications: true)
            let account = try #require(controller.tab(forAppTab: .me) as? UITabGroup)
            let manage = try #require(account.children.first as? UITabGroup)

            #expect(account.viewController === controller.meNavigationController)
            #expect(account.sidebarAppearance == .inline)
            #expect(manage.preferredPlacement == .sidebarOnly)
            #expect(manage.sidebarAppearance == .rootSection)
            #expect(manage.children.isEmpty)
            #expect(manage.sidebarActions.map(\.identifier) == [UIAction.Identifier("sidebar_help")])
            #expect(controller.tabs.allSatisfy { !$0.allowsHiding && $0.preferredPlacement == .fixed })
            #expect(!account.allowsReordering && !manage.allowsReordering)
            #expect(controller.sidebar.headerContentConfiguration != nil)
            #expect(controller.sidebar.bottomBarView != nil)
        }
    }

    @Test func helpPresentsASheetWithoutSelectingAnotherTab() throws {
        try withContext { _ in
            let controller = RecordingSidebarTabController(staticReader: true, staticNotifications: true)
            controller.showReaderTab()
            let account = try #require(controller.tab(forAppTab: .me) as? UITabGroup)
            let manage = try #require(account.children.first as? UITabGroup)
            let help = try #require(manage.sidebarActions.first { $0.identifier.rawValue == "sidebar_help" })

            help.performWithSender(nil, target: nil)

            let sheet = try #require(controller.recordedPresentation as? UINavigationController)
            #expect(sheet.modalPresentationStyle == .formSheet)
            #expect(
                sheet.topViewController?.navigationItem.rightBarButtonItem?.accessibilityIdentifier == "close-button"
            )
            #expect(controller.selectedAppTab == .reader)
            help.performWithSender(nil, target: nil)
            #expect(controller.presentationCount == 1)
        }
    }

    @Test func accountRoutesFollowSidebarAvailability() throws {
        try withContext { _ in
            let regular = RecordingSidebarTabController(staticReader: true, staticNotifications: true)
            regular.sidebarAvailable = true
            regular.showReaderTab()
            var presentedAccount: MeViewController?
            regular.showMeScreen { presentedAccount = $0 }
            let sheet = try #require(regular.recordedPresentation as? UINavigationController)
            #expect(sheet.topViewController === presentedAccount)
            #expect(sheet.modalPresentationStyle == .formSheet)
            #expect(regular.selectedAppTab == .reader)
            sheet.pushViewController(UIViewController(), animated: false)
            var reusedAccount: MeViewController?
            regular.showMeScreen { reusedAccount = $0 }
            #expect(reusedAccount === presentedAccount)
            #expect(sheet.viewControllers.count == 1)
            #expect(regular.presentationCount == 1)

            let tabOnly = RecordingSidebarTabController(staticReader: true, staticNotifications: true)
            // Regular width alone does not make a sidebar available on iPhone.
            tabOnly.traitOverrides.horizontalSizeClass = .regular
            tabOnly.showMeScreen { presentedAccount = $0 }
            #expect(tabOnly.recordedPresentation == nil)
            #expect(tabOnly.selectedAppTab == .me)
            #expect(presentedAccount === tabOnly.meViewController)
        }
    }

    @Test func changingSitesNotifiesSidebarButReselectingDoesNotResetIt() throws {
        try withContext { context in
            let first = BlogBuilder(context.mainContext).with(isHostedAtWPCom: true).withAnAccount().build()
            let second = BlogBuilder(context.mainContext).with(isHostedAtWPCom: true).withAnAccount().build()
            let coordinator = MySitesCoordinator(onBecomeActiveTab: {})
            coordinator.selectSite(first)
            var selectedSites: [Blog?] = []
            coordinator.onSiteChanged = { selectedSites.append($0) }

            coordinator.selectSite(first)
            #expect(selectedSites.isEmpty)
            coordinator.selectSite(second)
            #expect(selectedSites.count == 1)
            #expect(selectedSites.contains { $0 === second })
        }
    }

    @Test func supportDestinationRespectsTheFeatureFlag() {
        let flag = RemoteFeatureFlag.newSupport
        let original = UserDefaults.standard.object(forKey: flag.key)
        defer { UserDefaults.standard.set(original, forKey: flag.key) }

        UserDefaults.standard.set(false, forKey: flag.key)
        #expect(SupportHome.makeViewController() is SupportTableViewController)
        UserDefaults.standard.set(true, forKey: flag.key)
        #expect(SupportHome.makeViewController() is RootSupportViewController)
    }

    private func withContext(_ body: (ContextManager) throws -> Void) rethrows {
        let original = ContextManager.overrideInstance
        let wasReaderSelected = UserDefaults.standard.isReaderSelected
        let recentSites = UserDefaults.standard.object(forKey: "RecentSites")
        let context = ContextManager.forTesting()
        ContextManager.overrideInstance = context
        UserDefaults.standard.isReaderSelected = false
        defer {
            context.mainContext.reset()
            ContextManager.overrideInstance = original
            UserDefaults.standard.isReaderSelected = wasReaderSelected
            UserDefaults.standard.set(recentSites, forKey: "RecentSites")
        }
        try body(context)
    }
}

private final class RecordingSidebarTabController: WPTabBarController {
    private(set) var recordedPresentation: UIViewController?
    private(set) var presentationCount = 0
    var sidebarAvailable = false

    override var isAppSidebarAvailable: Bool { sidebarAvailable }

    override var presentedViewController: UIViewController? { recordedPresentation }

    override func present(
        _ viewControllerToPresent: UIViewController,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        recordedPresentation = viewControllerToPresent
        presentationCount += 1
        completion?()
    }
}
