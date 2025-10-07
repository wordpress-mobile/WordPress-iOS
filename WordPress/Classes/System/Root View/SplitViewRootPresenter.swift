import Combine
import SwiftUI
import UIKit
import WordPressAuthenticator
import WordPressData
import WordPressUI
import WordPressShared

/// The presenter that uses triple-column navigation for `.regular` size classes
/// and a tab-bar based navigation for `.compact` size class.
final class SplitViewRootPresenter: RootViewPresenter {
    private let sidebarViewModel = SidebarViewModel()
    private let splitVC = UISplitViewController(style: .doubleColumn)
    private let tabBarVC: WPTabBarController
    private weak var sitePickerPopoverVC: UIViewController?
    private var cancellables: [AnyCancellable] = []

    /// Is the app displaying tab bar UI instead of the full split view UI (with sidebar).
    private var isDisplayingTabBar: Bool {
        if splitVC.isCollapsed {
            wpAssert(splitVC.viewController(for: .compact) == tabBarVC, "Split view is collapsed, but is not displaying the tab bar view controller")
            return true
        }

        return false
    }

    init() {
        tabBarVC = WPTabBarController(staticScreens: false)

        splitVC.delegate = self
        splitVC.view.accessibilityIdentifier = "root_vc"

        let sidebarVC = SidebarViewController(viewModel: sidebarViewModel)
        sidebarVC.topSplitViewController = splitVC
        splitVC.setViewController(sidebarVC, for: .primary)

        splitVC.setViewController(tabBarVC, for: .compact)

        sidebarViewModel.navigate = { [weak self] in
            self?.navigate(to: $0)
        }

        /// - warning: Important to load the view to trigger the presentation logic
        _ = sidebarVC.view
    }

    private func navigate(to step: SidebarNavigationStep) {
        switch step {
        case .allSites(let sourceRect):
            showSitePicker(sourceRect: sourceRect)
        case .addSite(let selection):
            showAddSiteScreen(selection: selection)
        case .help:
            let supportVC = SupportTableViewController()
            let navigationVC = UINavigationController(rootViewController: supportVC)
            navigationVC.modalPresentationStyle = .formSheet
            splitVC.present(navigationVC, animated: true)
        case .profile:
            showMeScreen(completion: nil)
        case .signIn:
            Task {
                await WordPressDotComAuthenticator().signIn(from: splitVC, context: .default)
            }
        }
    }

    private func showSitePicker(sourceRect: CGRect) {
        let sitePickerVC = SiteSwitcherViewController(
            configuration: BlogListConfiguration(shouldHideRecentSites: true),
            addSiteAction: { [weak self] in
                self?.showAddSiteScreen(selection: $0)
            },
            onSiteSelected: { [weak self] site in
                self?.splitVC.dismiss(animated: true)
                RecentSitesService().touch(blog: site)
                self?.sidebarViewModel.didSelectSite(site)
            }
        )
        let navigationVC = UINavigationController(rootViewController: sitePickerVC)
        navigationVC.modalPresentationStyle = .popover
        navigationVC.popoverPresentationController?.sourceView = splitVC.view
        navigationVC.popoverPresentationController?.sourceRect = sourceRect
        // Show no arrow and simply overlay the sidebar
        navigationVC.popoverPresentationController?.permittedArrowDirections = [.left]
        sitePickerPopoverVC = navigationVC
        self.splitVC.present(navigationVC, animated: true)
        WPAnalytics.track(.sidebarAllSitesTapped)
    }

    private func showAddSiteScreen(selection: AddSiteMenuViewModel.Selection) {
        AddSiteController(viewController: splitVC.presentedViewController ?? splitVC, source: "sidebar")
            .showSiteCreationScreen(selection: selection)
    }

    // MARK: – RootViewPresenter

    // MARK: RootViewPresenter (General)

    var rootViewController: UIViewController { splitVC }

    func currentlySelectedScreen() -> String {
        if splitVC.isCollapsed {
            return tabBarVC.currentlySelectedScreen()
        } else {
            switch sidebarViewModel.mode {
            case .sites: return WPTabBarCurrentlySelectedScreenSites
            case .reader: return WPTabBarCurrentlySelectedScreenReader
            }
        }
    }

    // MARK: RootViewPresenter (Sites)

    func currentlyVisibleBlog() -> Blog? {
        assert(Thread.isMainThread)
        return sidebarViewModel.siteViewModel?.site
    }

    func showBlogDetails(for blog: Blog, then subsection: BlogDetailsSubsection?, userInfo: [AnyHashable: Any]) {
        if splitVC.isCollapsed {
            tabBarVC.showBlogDetails(for: blog, then: subsection, userInfo: userInfo)
        } else {
            sidebarViewModel.didSelectSite(blog)
            if let subsection {
                // TODO: reimplement
//                wpAssert(siteContent != nil, "failed to open blog subsection")
//                siteContent?.showSubsection(subsection, userInfo: userInfo)
            }
        }
    }

    func showMySitesTab() {
        guard let blog = currentlyVisibleBlog() else { return }
        sidebarViewModel.didSelectSite(blog)
    }

    // MARK: RootViewPresenter (Reader)

    func showReader(path: ReaderNavigationPath?) {
        if splitVC.isCollapsed {
            tabBarVC.showReader(path: path)
        } else {
            sidebarViewModel.mode = .reader
            if let path {
                sidebarViewModel.readerPresenter.navigate(to: path)
            }
        }
    }

    // MARK: RootViewPresenter (Notifications)

    func showNotificationsTab(completion: ((NotificationsViewController) -> Void)?) {
        // TODO: reimplement
//        sidebarViewModel.selection = .notifications
//        completion?(notificationsContent.notificationsViewController)
    }

    // MARK: RootViewPresenter (Me)

    func showMeScreen(completion: ((MeViewController) -> Void)?) {
        if isDisplayingTabBar {
            tabBarVC.showMeScreen(completion: completion)
            return
        }

        let meVC = MeViewController()
        meVC.isSidebarModeEnabled = true
        meVC.navigationItem.rightBarButtonItem = {
            let button = UIBarButtonItem(title: SharedStrings.Button.done, primaryAction: .init { [weak self] _ in
                self?.splitVC.dismiss(animated: true)
            })
            button.setTitleTextAttributes([.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)], for: .normal)
            return button
        }()

        let navigationVC = UINavigationController(rootViewController: meVC)
        navigationVC.modalPresentationStyle = .formSheet
        splitVC.present(navigationVC, animated: true) {
            completion?(meVC)
        }
    }
}

extension SplitViewRootPresenter: UISplitViewControllerDelegate {
    func splitViewController(_ svc: UISplitViewController, willHide column: UISplitViewController.Column) {
        if column == .primary {
            sitePickerPopoverVC?.presentingViewController?.dismiss(animated: true)
        }
    }

    // TODO: refactor this
    func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
        // Make sure the tab bar controller (displayed in compact mode) shows the same blog as the one in split view.
        // TODO: do we still need rthis?
//        if let blog = siteContent?.blog, tabBarVC.mySitesCoordinator.currentBlog != siteContent?.blog {
//            tabBarVC.mySitesCoordinator.showBlogDetails(for: blog)
//        }
        switch sidebarViewModel.mode {
        case .sites:
            break
        case .reader:
            if let selection = sidebarViewModel.readerPresenter.sidebar.viewModel.selection {
                switch selection {
                case .main(let readerStaticScreen):
                    switch readerStaticScreen {
                    case .recent: tabBarVC.showReader(path: .recent)
                    case .discover: tabBarVC.showReader(path: .discover)
                    case .saved: tabBarVC.showReader()
                    case .likes: tabBarVC.showReader(path: .likes)
                    case .search: tabBarVC.showReader(path: .search)
                    case .subscrtipions, .lists, .tags:
                        wpAssertionFailure("not supported by Jetpack")
                    }
                case .allSubscriptions:
                    tabBarVC.showReader(path: .subscriptions)
                default:
                    tabBarVC.showReader()
                }
            }
        }
    }

    // TODO: (kean) do we need this?
    func splitViewControllerDidExpand(_ svc: UISplitViewController) {
        // Make sure the split view shows the same blog as the tab bar controller (displayed in the compact mode)
//        if let blog = tabBarVC.mySitesCoordinator.currentBlog,
//           case let .blog(blogID) = sidebarViewModel.selection,
//           blog.objectID != blogID.objectID {
//            sidebarViewModel.selection = .blog(TaggedManagedObjectID(blog))
//        }
    }
}
