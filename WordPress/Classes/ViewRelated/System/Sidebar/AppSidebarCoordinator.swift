import Combine
import SwiftUI
import UIKit
import WordPressData
import WordPressShared

/// Connects the native app sidebar to site selection and account tools.
@MainActor
@objc(AppSidebarCoordinator)
final class AppSidebarCoordinator: NSObject {
    private weak var tabBarController: WPTabBarController?
    private let model = SidebarViewModel()
    private var accountHost: UIHostingController<AppSidebarAccountView>?
    private var accountSubscription: AnyCancellable?

    init(tabBarController: WPTabBarController) {
        self.tabBarController = tabBarController
        super.init()
        model.blogListViewModel.sidebarViewModel = model
        accountSubscription = model.$account.dropFirst()
            .sink { [weak self] _ in
                self?.updateManagementActions()
            }
    }

    func makeAccountTab(controller: UIViewController) -> UITabGroup {
        let manage = UITabGroup(
            title: AppSidebarStrings.manage,
            image: nil,
            identifier: "manage",
            children: [],
            viewControllerProvider: nil
        )
        manage.preferredPlacement = .sidebarOnly
        manage.sidebarAppearance = .rootSection
        manage.sidebarActions = makeManagementActions()

        // The compact Me tab keeps its navigation stack; the sidebar uses the pinned account link.
        let account = UITabGroup(
            title: controller.tabBarItem.title ?? AppSidebarStrings.me,
            image: controller.tabBarItem.image,
            identifier: WPTab.me.identifier,
            children: [manage]
        ) { _ in controller }
        account.sidebarAppearance = .inline
        if #available(iOS 26, *) {
            account.isSidebarDestination = true
        }
        return account
    }

    func configure() {
        guard let tabBarController else { return }
        updateManagementActions()
        guard accountHost == nil else { return }

        tabBarController.sidebar.headerContentConfiguration = UIHostingConfiguration {
            AppSidebarSitesView(
                model: self.model,
                sites: self.model.blogListViewModel,
                onSelect: { [weak self] in self?.selectSite($0) },
                onAllSites: { [weak self] in self?.showSitePicker(sourceRect: $0) },
                onAddSite: { [weak self] in self?.showAddSite($0) }
            )
        }
        .margins(.all, 8)

        let host = UIHostingController(
            rootView: AppSidebarAccountView(
                model: model,
                onSelect: { [weak self] in self?.showAccount() },
                onSignIn: { [weak self] in self?.signIn() }
            )
        )
        accountHost = host
        tabBarController.addChild(host)
        host.view.backgroundColor = .clear
        host.sizingOptions = .intrinsicContentSize
        tabBarController.sidebar.bottomBarView = host.view
        host.didMove(toParent: tabBarController)
        tabBarController.mySitesCoordinator.onSiteChanged = { [weak self] _ in
            self?.selectionDidChange()
            self?.model.onAppear()
        }
        selectionDidChange()
        model.onAppear()
    }

    func selectionDidChange() {
        guard let tabBarController else { return }
        switch tabBarController.selectedAppTab {
        case .mySites:
            model.selection =
                tabBarController.mySitesCoordinator.currentBlog.map {
                    .blog(TaggedManagedObjectID($0))
                } ?? .welcome
        case .reader:
            model.selection = .reader
        case .notifications:
            model.selection = .notifications
        case .me:
            model.selection = nil
        }
    }

    private func updateManagementActions() {
        let account = tabBarController?.tab(forAppTab: .me) as? UITabGroup
        let manage = account?.children.first as? UITabGroup
        manage?.sidebarActions = makeManagementActions()
    }

    private func makeManagementActions() -> [UIAction] {
        var actions: [UIAction] = []
        if AppConfiguration.isJetpack, AccountHelper.isDotcomAvailable(), RemoteFeatureFlag.domainManagement.enabled() {
            actions.append(
                UIAction(
                    title: AppSidebarStrings.domains,
                    image: UIImage(systemName: "network"),
                    identifier: .init("sidebar_domains")
                ) { [weak self] _ in
                    self?.presentSheet(AllDomainsListViewController(), leadingCloseButton: true)
                }
            )
        }
        actions.append(
            UIAction(
                title: AppSidebarStrings.help,
                image: UIImage(systemName: "questionmark.circle"),
                identifier: .init("sidebar_help")
            ) { [weak self] _ in
                self?.presentSheet(SupportHome.makeViewController())
            }
        )
        return actions
    }

    func showAccount(completion: ((MeViewController) -> Void)? = nil) {
        if let navigation = tabBarController?.presentedViewController as? UINavigationController,
            let controller = navigation.viewControllers.first as? MeViewController
        {
            navigation.popToRootViewController(animated: false)
            completion?(controller)
            return
        }
        let controller = MeViewController()
        controller.isSidebarModeEnabled = true
        presentSheet(controller) { completion?(controller) }
    }

    private func presentSheet(
        _ controller: UIViewController,
        leadingCloseButton: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        guard let tabBarController, tabBarController.presentedViewController == nil else { return }
        let close = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak controller] _ in controller?.dismiss(animated: true) }
        )
        close.accessibilityIdentifier = "close-button"
        if leadingCloseButton {
            controller.navigationItem.leftBarButtonItem = close
        } else {
            controller.navigationItem.rightBarButtonItem = close
        }
        let navigation = UINavigationController(rootViewController: controller)
        navigation.modalPresentationStyle = .formSheet
        tabBarController.present(navigation, animated: true, completion: completion)
    }

    private func selectSite(_ blog: Blog) {
        tabBarController?.mySitesCoordinator.selectSite(blog)
        selectionDidChange()
    }

    private func showSitePicker(sourceRect: CGRect) {
        guard let tabBarController, tabBarController.presentedViewController == nil else { return }
        let picker = SiteSwitcherViewController(
            configuration: BlogListConfiguration(shouldHideRecentSites: true),
            addSiteAction: { [weak self] in self?.showAddSite($0) },
            onSiteSelected: { [weak self] blog in
                self?.tabBarController?.dismiss(animated: true) { self?.selectSite(blog) }
            }
        )
        let navigation = UINavigationController(rootViewController: picker)
        navigation.modalPresentationStyle = .popover
        navigation.popoverPresentationController?.sourceView = tabBarController.view
        navigation.popoverPresentationController?.sourceRect = tabBarController.view.convert(sourceRect, from: nil)
        navigation.popoverPresentationController?.permittedArrowDirections = [.left]
        tabBarController.present(navigation, animated: true)
        WPAnalytics.track(.sidebarAllSitesTapped)
    }

    private func showAddSite(_ selection: AddSiteMenuViewModel.Selection) {
        guard let tabBarController else { return }
        AddSiteController(
            viewController: tabBarController.presentedViewController ?? tabBarController,
            source: "sidebar"
        )
        .showSiteCreationScreen(selection: selection)
    }

    private func signIn() {
        guard let tabBarController else { return }
        Task {
            await WordPressDotComAuthenticator().signIn(from: tabBarController, context: .default)
        }
    }
}
