import Combine
import SwiftUI
import UIKit
import WordPressData
import WordPressShared
import WordPressUI

/// One navigation hierarchy for phone, compact iPad, and regular iPad.
final class AppTabBarController: UITabBarController, RootViewPresenter, UITabBarControllerDelegate {
    private let appUIType: RootViewCoordinator.AppUIType
    private let sidebarModel = SidebarViewModel()
    private var site: AdaptiveSiteNavigation?
    private var reader: AdaptiveReaderNavigation?
    private var accountHost: UIHostingController<AdaptiveSidebarAccountView>?
    private var cancellables: [AnyCancellable] = []

    private lazy var notifications = Notifications.instantiateInitialViewController()
    private lazy var notificationContent: AdaptiveListDetailViewController = {
        let content = AdaptiveListDetailViewController(list: notifications)
        notifications.adaptiveDetailHandler = { [weak content] in content?.showDetail($0) }
        notifications.isAdaptiveDetailVisible = { [weak content] in content?.isShowingAlongsideDetail ?? false }
        return content
    }()
    private lazy var me = MeViewController()
    private lazy var meNavigation = UINavigationController(rootViewController: me)

    init(appUIType: RootViewCoordinator.AppUIType) {
        self.appUIType = appUIType
        super.init(nibName: nil, bundle: nil)
        mode = .tabSidebar
        delegate = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "root_vc"
        tabBar.accessibilityIdentifier = "Main Navigation"
        view.tintColor = UIAppColor.primary
        sidebarModel.blogListViewModel.sidebarViewModel = sidebarModel
        configureTabs(blog: Blog.lastUsedOrFirst(in: ContextManager.shared.mainContext))
        configureSidebar()
        observeChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sidebarModel.onAppear()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTabBarVisibility(animated: false)
    }

    func updateTabBarVisibility(animated: Bool) {
        let requestsHiddenBottomBar: Bool
        if let content = selectedViewController as? AdaptiveListDetailViewController {
            requestsHiddenBottomBar = content.requestsHiddenBottomBar
        } else {
            requestsHiddenBottomBar =
                (selectedViewController as? UINavigationController)?.requestsHiddenBottomBar ?? false
        }
        let isHidden = traitCollection.horizontalSizeClass == .compact && requestsHiddenBottomBar
        guard isTabBarHidden != isHidden else { return }
        setTabBarHidden(isHidden, animated: animated)
    }

    private func makeSiteNavigation(blog: Blog?) -> AdaptiveSiteNavigation {
        let site = AdaptiveSiteNavigation(blog: blog)
        site.onSiteSelected = { [weak self] blog in
            if let blog { self?.switchSite(to: blog) } else { self?.replaceSite(with: nil) }
        }
        return site
    }

    private func configureTabs(blog: Blog?) {
        let site = makeSiteNavigation(blog: blog)
        self.site = site
        var tabs: [UITab] = [site.tab]
        if appUIType != .simplified {
            if appUIType == .staticScreens {
                tabs.append(
                    makeStaticTab(
                        source: .reader,
                        title: SharedStrings.Reader.title,
                        image: "eyeglasses",
                        identifier: "reader"
                    )
                )
            } else {
                let reader = AdaptiveReaderNavigation()
                self.reader = reader
                tabs.append(reader.tab)
            }
            let notificationTab =
                appUIType == .staticScreens
                ? makeStaticTab(
                    source: .notifications,
                    title: NSLocalizedString("Notifications", comment: "Notifications tab"),
                    image: "bell",
                    identifier: "notifications"
                )
                : UITab(
                    title: NSLocalizedString("Notifications", comment: "Notifications tab"),
                    image: UIImage(systemName: "bell"),
                    identifier: "notifications"
                ) { [weak self] _ in self?.notificationContent ?? UIViewController() }
            notificationTab.preferredPlacement = .fixed
            notificationTab.accessibilityIdentifier = "tabbar_notifications"
            tabs.append(notificationTab)
        }
        // An inline group keeps the account destination in the compact tab bar;
        // the sidebar's account control supplies its familiar bottom entrance.
        let account = UITabGroup(
            title: NSLocalizedString("Me", comment: "The account tab"),
            image: UIImage(systemName: "person.crop.circle"),
            identifier: "me",
            children: []
        ) { [weak self] _ in self?.meNavigation ?? UIViewController() }
        account.sidebarAppearance = .inline
        account.children = [makeManagementSection()]
        account.preferredPlacement = .fixed
        account.accessibilityIdentifier = "tabbar_me"
        tabs.append(account)
        setTabs(tabs, animated: false)
        compactTabIdentifiers = tabs.map(\.identifier)
        selectedTab = site.tab
        if let blog {
            sidebarModel.selection = .blog(TaggedManagedObjectID(blog))
        }
        updateNotificationsBadge()
    }

    private func makeManagementSection() -> UITabGroup {
        let manage = UITabGroup(
            title: NSLocalizedString(
                "sidebar.manage",
                value: "Manage",
                comment: "Sidebar section containing account tools and help"
            ),
            image: nil,
            identifier: "manage",
            children: [],
            viewControllerProvider: nil
        )
        manage.preferredPlacement = .sidebarOnly
        manage.sidebarAppearance = .rootSection
        manage.sidebarActions = [
            UIAction(
                title: NSLocalizedString("sidebar.help", value: "Help & Support", comment: "Sidebar item on iPad"),
                image: UIImage(systemName: "questionmark.circle")
            ) { [weak self] _ in self?.presentSidebarSheet(SupportTableViewController()) }
        ]
        if AppConfiguration.isJetpack, AccountHelper.isDotcomAvailable(), RemoteFeatureFlag.domainManagement.enabled() {
            manage.sidebarActions.insert(
                UIAction(
                    title: NSLocalizedString("sidebar.domains", value: "Domains", comment: "Sidebar item on iPad"),
                    image: UIImage(systemName: "network")
                ) { [weak self] _ in self?.presentDomainsSheet() },
                at: 0
            )
        }
        return manage
    }

    private func presentDomainsSheet() {
        let domains = AllDomainsListViewController()
        domains.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak domains] _ in domains?.dismiss(animated: true) }
        )
        domains.navigationItem.leftBarButtonItem?.accessibilityIdentifier = "close-button"
        presentSidebarSheet(domains)
    }

    private func presentAccountSheet() {
        let profile = MeViewController()
        profile.isSidebarModeEnabled = true
        profile.navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak profile] _ in profile?.dismiss(animated: true) }
        )
        profile.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "close-button"
        presentSidebarSheet(profile)
    }

    private func presentSidebarSheet(_ viewController: UIViewController) {
        let navigation = UINavigationController(rootViewController: viewController)
        navigation.modalPresentationStyle = .formSheet
        present(navigation, animated: true)
    }

    private func makeStaticTab(
        source: MovedToJetpackSource,
        title: String,
        image: String,
        identifier: String
    ) -> UITab {
        let tab = UITab(title: title, image: UIImage(systemName: image), identifier: identifier) { _ in
            UINavigationController(rootViewController: MovedToJetpackViewController(source: source))
        }
        tab.preferredPlacement = .fixed
        return tab
    }

    private func configureSidebar() {
        sidebar.headerContentConfiguration = UIHostingConfiguration {
            AdaptiveSidebarSitesView(
                model: sidebarModel,
                sites: sidebarModel.blogListViewModel,
                onSelect: { [weak self] in self?.switchSite(to: $0) },
                onAllSites: { [weak self] in self?.showSitePicker(sourceRect: $0) },
                onAddSite: { [weak self] in self?.addSite($0) }
            )
        }
        .margins(.all, 8)
        let host = UIHostingController(
            rootView: AdaptiveSidebarAccountView(
                model: sidebarModel,
                onSelect: { [weak self] in self?.presentAccountSheet() },
                onSignIn: { [weak self] in self?.signIn() }
            )
        )
        accountHost = host
        addChild(host)
        host.view.backgroundColor = .clear
        host.sizingOptions = .intrinsicContentSize
        sidebar.bottomBarView = host.view
        host.didMove(toParent: self)
    }

    private func observeChanges() {
        NotificationCenter.default.publisher(for: .notificationActivityDidChange)
            .sink { [weak self] _ in self?.updateNotificationsBadge() }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: MySiteViewController.didPickSiteNotification)
            .sink { [weak self] note in
                guard let blog = note.userInfo?[MySiteViewController.siteUserInfoKey] as? Blog else { return }
                self?.switchSite(to: blog)
            }
            .store(in: &cancellables)
        NotificationCenter.default
            .publisher(for: .init(rawValue: WordPressAuthenticationManager.WPSigninDidFinishNotification))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.configureTabs(blog: Blog.lastUsedOrFirst(in: ContextManager.shared.mainContext))
                self?.sidebarModel.onAppear()
            }
            .store(in: &cancellables)
    }

    private func updateNotificationsBadge() {
        tabs.first { $0.identifier == "notifications" }?.image = UIImage(
            systemName: NotificationActivityService.shared.hasNewActivity ? "bell.badge" : "bell"
        )
    }

    private func switchSite(to blog: Blog) {
        if site?.blog?.objectID == blog.objectID {
            if selectedTab?.rootIdentifier != "site" {
                selectedTab = site?.tab
            }
            return
        }
        RecentSitesService().touch(blog: blog)
        replaceSite(with: blog)
    }

    private func replaceSite(with blog: Blog?) {
        let updated = makeSiteNavigation(blog: blog)
        site = updated
        var updatedTabs = tabs
        updatedTabs[0] = updated.tab
        setTabs(updatedTabs, animated: false)
        compactTabIdentifiers = updatedTabs.map(\.identifier)
        selectedTab = updated.tab
        sidebarModel.selection = blog.map { .blog(TaggedManagedObjectID($0)) } ?? .welcome
        sidebarModel.blogListViewModel.updateDisplayedSites()
    }

    private func showSitePicker(sourceRect: CGRect) {
        let picker = SiteSwitcherViewController(
            configuration: BlogListConfiguration(shouldHideRecentSites: true),
            addSiteAction: { [weak self] in self?.addSite($0) },
            onSiteSelected: { [weak self] blog in
                self?.dismiss(animated: true) { self?.switchSite(to: blog) }
            }
        )
        let navigation = UINavigationController(rootViewController: picker)
        navigation.modalPresentationStyle = .popover
        navigation.popoverPresentationController?.sourceView = view
        navigation.popoverPresentationController?.sourceRect = view.convert(sourceRect, from: nil)
        present(navigation, animated: true)
        WPAnalytics.track(.sidebarAllSitesTapped)
    }

    private func addSite(_ selection: AddSiteMenuViewModel.Selection) {
        AddSiteController(viewController: presentedViewController ?? self, source: "sidebar")
            .showSiteCreationScreen(selection: selection)
    }

    private func signIn() {
        Task { await WordPressDotComAuthenticator().signIn(from: self, context: .default) }
    }

    var rootViewController: UIViewController { self }

    func currentlySelectedScreen() -> String {
        switch selectedTab?.rootIdentifier {
        case "site": WPTabBarCurrentlySelectedScreenSites
        case "reader": WPTabBarCurrentlySelectedScreenReader
        case "notifications": WPTabBarCurrentlySelectedScreenNotifications
        default: "Me"
        }
    }

    func currentlyVisibleBlog() -> Blog? {
        selectedTab?.rootIdentifier == "site" ? site?.blog : nil
    }

    func showMySitesTab() {
        loadViewIfNeeded()
        selectedTab = site?.tab
    }

    func showBlogDetails(for blog: Blog, then subsection: BlogDetailsRowKind?, userInfo: [String: Any]) {
        loadViewIfNeeded()
        switchSite(to: blog)
        if let subsection {
            site?.show(subsection, userInfo: userInfo)
        }
    }

    func showReader(path: ReaderNavigationPath?) {
        loadViewIfNeeded()
        guard let tab = tabs.first(where: { $0.identifier == "reader" }) else {
            return showJetpackOverlayForDisabledEntryPoint()
        }
        selectedTab = tab
        if let path { reader?.presenter.navigate(to: path) }
    }

    func showNotificationsTab(completion: ((NotificationsViewController) -> Void)?) {
        loadViewIfNeeded()
        guard let tab = tabs.first(where: { $0.identifier == "notifications" }) else {
            return showJetpackOverlayForDisabledEntryPoint()
        }
        selectedTab = tab
        if appUIType != .staticScreens { completion?(notifications) }
    }

    func showMeScreen(completion: ((MeViewController) -> Void)?) {
        loadViewIfNeeded()
        selectedTab = tabs.first { $0.identifier == "me" }
        if let completion {
            meNavigation.popToRootViewController(animated: false)
            me.loadViewIfNeeded()
            completion(me)
        }
    }

    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelectTab selectedTab: UITab,
        previousTab: UITab?
    ) {
        updateTabBarVisibility(animated: false)
        switch selectedTab.rootIdentifier {
        case "site": WPAnalytics.track(.mySitesTabAccessed)
        case "reader": WPAnalytics.track(.readerAccessed)
        default: break
        }
    }
}

private extension UITab {
    var rootIdentifier: String { parent?.rootIdentifier ?? String(identifier.split(separator: ".")[0]) }
}
