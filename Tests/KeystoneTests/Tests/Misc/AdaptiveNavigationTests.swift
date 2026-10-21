import OHHTTPStubs
import Testing
import UIKit

@testable import WordPress
@testable import WordPressData

@MainActor
@Suite(.serialized)
struct AdaptiveNavigationTests {
    @Test func widthChangesKeepTheSelectedScreenAndBackHistory() async throws {
        try await withApp { root, context in
            let blog = makeBlog(in: context)
            root.showBlogDetails(for: blog, then: .posts)
            await settleNavigation()
            let navigation = try siteNavigation(in: root)
            #expect(root.selectedTab === root.tabs.first)
            #expect(navigation.viewControllers.first is MySiteViewController)
            let posts = try #require(navigation.topViewController as? PostListViewController)
            let detail = UIViewController()
            #expect(navigation.view.window != nil)
            navigation.pushViewController(detail, animated: false)
            #expect(navigation.topViewController === detail)
            await settleNavigation()

            #expect(navigation.viewControllers.contains { $0 === posts })
            for width: UIUserInterfaceSizeClass in [.compact, .regular, .compact, .regular] {
                root.traitOverrides.horizontalSizeClass = width
                root.view.layoutIfNeeded()
                await settleNavigation()
                #expect(navigation.topViewController.map(ObjectIdentifier.init) == ObjectIdentifier(detail))
                #expect(navigation.viewControllers.contains { $0 === posts })
                #expect(root.selectedTab === root.tabs.first)
            }
            navigation.popViewController(animated: false)
            #expect(navigation.topViewController.map(ObjectIdentifier.init) == ObjectIdentifier(posts))
        }
    }

    @Test(arguments: [DashboardQuickAction.posts, .more])
    func dashboardNavigationKeepsHomeAndBackHistory(action: DashboardQuickAction) async throws {
        try await withApp { root, context in
            let blog = makeBlog(in: context)
            root.showBlogDetails(for: blog)
            await settleNavigation()
            let navigation = try siteNavigation(in: root)
            let home = try #require(navigation.topViewController as? MySiteViewController)
            let dashboard = BlogDashboardViewController(blog: blog, embeddedInScrollView: true)
            home.addChild(dashboard)
            home.view.addSubview(dashboard.view)
            dashboard.didMove(toParent: home)
            let model = DashboardQuickActionsViewModel(
                blog: blog,
                personalizationService: BlogDashboardPersonalizationService(
                    repository: InMemoryUserDefaults(),
                    siteID: 1
                )
            )
            let cell = DashboardQuickActionsCardCell(frame: .zero)
            cell.configure(viewModel: model, viewController: dashboard)
            defer { withExtendedLifetime(cell) {} }
            let row = try #require(model.items.firstIndex { $0.action == action })
            cell.tableView(UITableView(), didSelectRowAt: IndexPath(row: row, section: 0))
            await settleNavigation()
            var menu: BlogDetailsViewController?
            if action == .more {
                menu = try #require(navigation.topViewController as? BlogDetailsViewController)
                menu?.showDetailView(for: .posts)
                await settleNavigation()
            }
            let posts = try #require(navigation.topViewController as? PostListViewController)
            #expect(root.selectedTab === root.tabs.first)
            #expect(navigation.viewControllers.first === home)
            #expect(navigation.viewControllers.count == (action == .more ? 3 : 2))

            for width: UIUserInterfaceSizeClass in [.compact, .regular] {
                root.traitOverrides.horizontalSizeClass = width
                root.view.layoutIfNeeded()
                await settleNavigation()
                #expect(navigation.topViewController === posts)
                #expect(root.selectedTab === root.tabs.first)
            }
            root.showMeScreen()
            await settleNavigation()
            root.showMySitesTab()
            await settleNavigation()
            #expect(navigation.topViewController === posts)
            navigation.popViewController(animated: false)
            await settleNavigation()
            if let menu {
                #expect(navigation.topViewController === menu)
                navigation.popViewController(animated: false)
                await settleNavigation()
            }
            #expect(navigation.topViewController === home)
        }
    }

    @Test func switchingSectionsKeepsSiteNavigation() async throws {
        try await withApp { root, context in
            let blog = makeBlog(in: context)
            root.showBlogDetails(for: blog, then: .posts)
            await settleNavigation()
            let navigation = try siteNavigation(in: root)
            let detail = UIViewController()
            #expect(navigation.view.window != nil)
            navigation.pushViewController(detail, animated: false)
            #expect(navigation.topViewController === detail)
            await settleNavigation()
            root.showMeScreen()
            await settleNavigation()
            root.showMySitesTab()
            await settleNavigation()

            #expect(navigation.topViewController.map(ObjectIdentifier.init) == ObjectIdentifier(detail))
            #expect(root.currentlyVisibleBlog()?.objectID == blog.objectID)
        }
    }

    @Test func switchingSitesDiscardsThePreviousSitesStack() async throws {
        try await withApp { root, context in
            let first = makeBlog(in: context)
            let second = makeBlog(in: context)
            root.showBlogDetails(for: first, then: .posts)
            await settleNavigation()
            let previous = try siteNavigation(in: root)
            previous.pushViewController(UIViewController(), animated: false)
            await settleNavigation()
            root.showBlogDetails(for: second)
            await settleNavigation()
            let current = try siteNavigation(in: root)

            #expect(current !== previous)
            #expect(current.viewControllers.count == 1)
            #expect(current.topViewController is MySiteViewController)
            #expect(root.currentlyVisibleBlog()?.objectID == second.objectID)

            root.showBlogDetails(for: first)
            await settleNavigation()
            let returned = try siteNavigation(in: root)
            #expect(returned !== previous)
            #expect(returned.viewControllers.count == 1)
        }
    }

    @Test func destinationsOutsideTheSidebarRemainReachable() async throws {
        try await withApp { root, context in
            let blog = makeBlog(in: context)
            root.showBlogDetails(for: blog, then: .media)
            await settleNavigation()
            let navigation = try siteNavigation(in: root)
            let media = try #require(navigation.topViewController)
            #expect(!(media is MySiteViewController))
            #expect(navigation.viewControllers.count == 2)
            #expect(!(root.tabs.first is UITabGroup))
            #expect(navigation.viewControllers.first is MySiteViewController)

            root.showMeScreen()
            await settleNavigation()
            root.showMySitesTab()
            await settleNavigation()
            #expect(navigation.topViewController === media)
        }
    }

    @Test func statsRouteKeepsBackNavigation() async throws {
        // Initialize the coordinator before overriding the feature state it sets on creation.
        _ = RootViewCoordinator.shared
        let previousAppUIType = JetpackFeaturesRemovalCoordinator.currentAppUIType
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .normal
        defer { JetpackFeaturesRemovalCoordinator.currentAppUIType = previousAppUIType }
        try await withApp { root, context in
            let blog = BlogBuilder(context).with(isAdmin: true).with(isHostedAtWPCom: true).withAnAccount().build()
            root.showBlogDetails(for: blog)
            await settleNavigation()
            let navigation = try siteNavigation(in: root)
            let home = try #require(navigation.topViewController as? MySiteViewController)
            root.showStats(for: blog)
            await settleNavigation()
            let stats = try #require(navigation.topViewController as? StatsViewController)
            #expect(navigation.viewControllers.count == 2)
            #expect(navigation.viewControllers.first === home)
            #expect(root.selectedTab === root.tabs.first)
            #expect(!(root.tabs.first is UITabGroup))
            for width: UIUserInterfaceSizeClass in [.compact, .regular] {
                root.traitOverrides.horizontalSizeClass = width
                root.view.layoutIfNeeded()
                await settleNavigation()
                #expect(navigation.topViewController === stats)
                #expect(navigation.navigationBar.backItem === home.navigationItem)
                #expect(stats.navigationItem.leftBarButtonItem == nil)
            }
            navigation.popViewController(animated: false)
            await settleNavigation()
            #expect(navigation.topViewController === home)
        }
    }

    @Test func sidebarStatsReturnsToDashboardAfterCollapsing() async throws {
        try await withApp { root, context in
            root.showBlogDetails(for: makeBlog(in: context))
            await settleNavigation()
            let content = try #require(root.tabs.first?.viewController as? AdaptiveListDetailViewController)
            let navigation = content.detailNavigationController
            let home = try #require(navigation.topViewController as? MySiteViewController)
            let dashboard = try #require(home.children.compactMap { $0 as? BlogDashboardViewController }.first)
            let dataSource = try #require(dashboard.collectionView.dataSource as? DashboardDataSource)
            #expect(!dataSource.snapshot().sectionIdentifiers.contains(.quickActions))
            let menu = try #require(content.listNavigationController.viewControllers.first as? SiteMenuViewController)
            menu.showSubsection(.stats, userInfo: [:])
            await settleNavigation()
            let stats = try #require(navigation.topViewController as? StatsViewController)

            root.traitOverrides.horizontalSizeClass = .compact
            root.view.layoutIfNeeded()
            await settleNavigation()
            #expect(content.splitViewControllerForContent.isCollapsed)
            #expect(stats.view.window != nil)
            #expect(navigation.viewControllers.first === home)
            navigation.popViewController(animated: false)
            await settleNavigation()
            #expect(navigation.topViewController === home)
            #expect(home.view.window != nil)
            #expect(navigation.viewControllers.count == 1)
            #expect(navigation.navigationBar.backItem == nil)
            #expect(content.listNavigationController.viewIfLoaded?.window == nil)
            #expect(dataSource.snapshot().sectionIdentifiers.contains(.quickActions))

            root.traitOverrides.horizontalSizeClass = .regular
            root.view.layoutIfNeeded()
            await settleNavigation()
            #expect(home.view.window != nil)
            #expect(menu.view.window != nil)
            let menuList = try #require(menu.children.first as? BlogDetailsViewController)
            #expect(menuList.tableView?.indexPathForSelectedRow == menuList.tableViewModel?.indexPath(for: .home))
            #expect(menuList.tableViewModel?.restorableSelectedRow == .home)
            #expect(!dataSource.snapshot().sectionIdentifiers.contains(.quickActions))
        }
    }

    @Test func compactLaunchShowsDashboardAndAdaptsQuickActions() async throws {
        try await withApp { root, context in
            root.traitOverrides.horizontalSizeClass = .compact
            root.showBlogDetails(for: makeBlog(in: context))
            root.view.layoutIfNeeded()
            await settleNavigation()
            let navigation = try siteNavigation(in: root)
            let home = try #require(navigation.topViewController as? MySiteViewController)
            let dashboard = try #require(home.children.compactMap { $0 as? BlogDashboardViewController }.first)
            let dataSource = try #require(dashboard.collectionView.dataSource as? DashboardDataSource)
            for width: UIUserInterfaceSizeClass in [.compact, .regular, .compact, .regular] {
                root.traitOverrides.horizontalSizeClass = width
                root.view.layoutIfNeeded()
                await settleNavigation()
                #expect(navigation.topViewController === home)
                #expect(home.view.window != nil)
                #expect(dataSource.snapshot().sectionIdentifiers.contains(.quickActions) == (width == .compact))
            }
            let split = try #require(home.splitViewController)
            split.hide(.primary)
            await settleNavigation()
            #expect(dataSource.snapshot().sectionIdentifiers.contains(.quickActions))
            split.show(.primary)
            await settleNavigation()
            #expect(!dataSource.snapshot().sectionIdentifiers.contains(.quickActions))
        }
    }

    @Test func supportRouteWorksBeforeOpeningMe() async throws {
        try await withApp { root, _ in
            root.navigateToSupport()
            await settleNavigation()
            let navigation = try #require(root.selectedViewController as? UINavigationController)
            #expect(navigation.viewControllers.first is MeViewController)
            #expect(navigation.viewControllers.count == 2)
            #expect(!(navigation.topViewController is MeViewController))
        }
    }

    @Test func listDetailKeepsTheVisibleDetailAcrossWidths() async throws {
        try await withApp { root, _ in
            let list = UIViewController()
            let detail = UIViewController()
            let content = AdaptiveListDetailViewController(list: list)
            let tab = UITab(title: "List", image: nil, identifier: "list") { _ in content }
            root.tabs.append(tab)
            root.selectedTab = tab
            await settleNavigation()
            content.showDetail(detail)
            await settleNavigation()
            let detailNavigation = try #require(detail.navigationController)

            for width: UIUserInterfaceSizeClass in [.compact, .regular, .compact, .regular] {
                root.traitOverrides.horizontalSizeClass = width
                root.view.layoutIfNeeded()
                await settleNavigation()
                #expect(detail.view.window != nil)
                #expect(detail.navigationController === detailNavigation)
                #expect(content.listNavigationController.viewControllers.first === list)
            }
        }
    }

    @Test func postFiltersFillTheVisibleColumnAndKeepSelection() async throws {
        try await withApp { root, context in
            root.showBlogDetails(for: makeBlog(in: context), then: .posts)
            await settleNavigation()
            let navigation = try siteNavigation(in: root)
            let posts = try #require(navigation.topViewController as? PostListViewController)
            let filters = posts.filterTabBar
            filters.setSelectedIndex(1, animated: false)
            filters.sendActions(for: .valueChanged)
            for width: UIUserInterfaceSizeClass in [.regular, .compact, .regular] {
                root.traitOverrides.horizontalSizeClass = width
                root.view.layoutIfNeeded()
                await settleNavigation()
                #expect(filters.selectedIndex == 1)
                if width == .regular {
                    let button = try #require(findView(withIdentifier: "published", in: filters) as? UIButton)
                    let visibleWidth = filters.bounds.inset(by: filters.safeAreaInsets).width
                    #expect(abs(button.bounds.width - visibleWidth / CGFloat(filters.items.count)) < 1)
                }
            }
        }
    }

    private func findView(withIdentifier identifier: String, in view: UIView) -> UIView? {
        if view.accessibilityIdentifier == identifier { return view }
        for subview in view.subviews {
            if let match = findView(withIdentifier: identifier, in: subview) { return match }
        }
        return nil
    }

    @Test func siteMenuSelectsContentInEitherWidth() async throws {
        try await withApp { root, context in
            root.showBlogDetails(for: makeBlog(in: context))
            await settleNavigation()
            let content = try #require(root.tabs.first?.viewController as? AdaptiveListDetailViewController)
            let menu = try #require(content.listNavigationController.viewControllers.first as? SiteMenuViewController)
            let navigation = content.detailNavigationController
            for width: UIUserInterfaceSizeClass in [.regular, .compact] {
                root.traitOverrides.horizontalSizeClass = width
                root.view.layoutIfNeeded()
                await settleNavigation()
                menu.showSubsection(.posts, userInfo: [:])
                await settleNavigation()
                #expect(navigation.topViewController is PostListViewController)
                #expect(navigation.viewControllers.count == 2)
                #expect(navigation.viewControllers.first is MySiteViewController)
                #expect(navigation.topViewController?.view.window != nil)
                menu.showSubsection(.stats, userInfo: [:])
                await settleNavigation()
                #expect(navigation.topViewController is StatsViewController)
                #expect(navigation.viewControllers.count == 2)
                #expect(navigation.viewControllers.first is MySiteViewController)
                #expect(content.listNavigationController.viewControllers.first === menu)
                #expect(!content.listNavigationController.viewControllers.contains { $0 is StatsViewController })
            }
        }
    }

    @Test func selfHostedSiteUsesItsInitialScreen() async throws {
        try await withApp { root, context in
            JetpackFeaturesRemovalCoordinator.currentAppUIType = .simplified
            let blog = BlogBuilder(context).with(username: "navigation-test").with(password: "unused").build()
            root.showBlogDetails(for: blog)
            await settleNavigation()
            let navigation = try siteNavigation(in: root)
            #expect(navigation.viewControllers.count == 2)
            #expect(navigation.viewControllers.first is MySiteViewController)
            #expect(navigation.topViewController is PostListViewController)
        }
    }

    @Test func readerKeepsItsFeedAndArticleAcrossWidths() async throws {
        try await withApp { root, context in
            let account = AccountBuilder(context).build()
            let previousAccount = UserSettings.defaultDotComUUID
            UserSettings.defaultDotComUUID = account.uuid
            defer { UserSettings.defaultDotComUUID = previousAccount }
            let presenter = ReaderPresenter()
            presenter.sidebar.viewModel.selection = .main(.saved)
            let content = try #require(presenter.prepareForAdaptivePresentation() as? AdaptiveListDetailViewController)
            let tab = UITab(title: "Reader", image: nil, identifier: "reader-test") { _ in content }
            root.tabs.append(tab)
            root.selectedTab = tab
            await settleNavigation()
            let navigation = content.detailNavigationController
            let feed = try #require(navigation.topViewController as? ReaderStreamViewController)
            presenter.navigate(to: .post(postID: 1, siteID: 1, isFeed: false), animated: false)
            await settleNavigation()
            let article = try #require(navigation.topViewController as? ReaderDetailViewController)

            for width: UIUserInterfaceSizeClass in [.compact, .regular, .compact, .regular] {
                root.traitOverrides.horizontalSizeClass = width
                root.view.layoutIfNeeded()
                await settleNavigation()
                #expect(article.view.window != nil)
                #expect(navigation.topViewController === article)
                #expect(navigation.viewControllers.first === feed)
                #expect(presenter.sidebar.viewModel.selection == .main(.saved))
            }
            presenter.sidebar.viewModel.selection = .main(.saved)
            await settleNavigation()
            #expect(navigation.topViewController === feed)
            #expect(navigation.viewControllers.count == 1)
        }
    }

    private func siteNavigation(in root: AppTabBarController) throws -> UINavigationController {
        let content = try #require(root.tabs.first?.viewController as? AdaptiveListDetailViewController)
        #expect(root.selectedViewController === content)
        return content.detailNavigationController
    }

    private func makeBlog(in context: NSManagedObjectContext) -> Blog {
        BlogBuilder(context).with(isAdmin: true).with(isHostedAtWPCom: true).withAnAccount().build()
    }

    private func withApp(_ body: (AppTabBarController, NSManagedObjectContext) async throws -> Void) async throws {
        _ = RootViewCoordinator.shared
        let previousAppUIType = JetpackFeaturesRemovalCoordinator.currentAppUIType
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .normal
        defer { JetpackFeaturesRemovalCoordinator.currentAppUIType = previousAppUIType }
        let coreData = ContextManager.forTesting()
        let previousContext = ContextManager.overrideInstance
        ContextManager.overrideInstance = coreData
        let stub = HTTPStubs.stubRequests(passingTest: { _ in true }) { _ in
            HTTPStubsResponse(error: URLError(.notConnectedToInternet))
        }
        let root = AppTabBarController(appUIType: .simplified)
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previousWindow = scene.keyWindow
        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 1194, height: 834)
        window.rootViewController = root
        root.traitOverrides.horizontalSizeClass = .regular
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            previousWindow?.makeKeyAndVisible()
            UIView.setAnimationsEnabled(animationsWereEnabled)
            HTTPStubs.removeStub(stub)
            ContextManager.overrideInstance = previousContext
        }
        await settleNavigation()
        try await body(root, coreData.mainContext)
    }

    private func settleNavigation() async {
        // UIKit records pushed controllers when the navigation transition finishes.
        try? await Task.sleep(for: .milliseconds(500))
    }
}
