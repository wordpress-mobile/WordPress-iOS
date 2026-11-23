import UIKit

extension WPTabBarController {
    @objc func observeAdaptiveTabBarTraits() {
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) {
            (controller: WPTabBarController, _: UITraitCollection) in
            controller.updateAdaptiveTabBarVisibility(animated: false)
        }
    }

    @objc func makeNotificationsRootViewController() -> UIViewController {
        let navigation = notificationsNavigationController
        guard let notificationsViewController else { return navigation }
        let content = AdaptiveListDetailViewController(list: navigation)
        content.tabBarItem = navigation.tabBarItem
        notificationsViewController.showAdaptiveDetail = { [weak content] in content?.showDetail($0) }
        content.onCollapseStateChanged = { [weak notificationsViewController] _ in
            // Auto-selection can show a column, which UIKit forbids inside split-view delegate callbacks.
            DispatchQueue.main.async {
                notificationsViewController?.updateSelectionForLayout()
            }
        }
        content.onReturnToList = { [weak content, weak notificationsViewController] in
            notificationsViewController?.didReturnToAdaptiveList()
            content?.resetDetail()
        }
        notificationsViewController.isAdaptiveDetailVisible = { [weak content] in
            content?.isShowingAlongsideDetail ?? false
        }
        return content
    }

    @objc func resetNotificationsNavigation() {
        if let content = notificationsRootViewController as? AdaptiveListDetailViewController {
            content.resetDetail()
        }
        notificationsNavigationController.popToRootViewController(animated: false)
    }

    @objc(updateAdaptiveTabBarVisibilityAnimated:) func updateAdaptiveTabBarVisibility(animated: Bool) {
        // Resizing does not push the retained detail again, so UIKit does not reapply its preference.
        let content =
            selectedAppTab == .mySites
            ? mySitesCoordinator.adaptiveContent
            : selectedViewController as? AdaptiveListDetailViewController
        let requestsHiddenBar =
            content?.requestsHiddenBottomBar
            ?? (selectedViewController as? UINavigationController)?.requestsHiddenBottomBar
            ?? false
        let isHidden = !isAppSidebarAvailable && requestsHiddenBar
        guard isTabBarHidden != isHidden else { return }
        setTabBarHidden(isHidden, animated: animated)
    }
}

extension UITabBarController {
    @objc var isAppSidebarAvailable: Bool {
        if #available(iOS 27, *) {
            return sidebar.isAvailable
        }
        // Earlier iPhone systems keep bottom tabs even in regular-width landscape.
        return UIDevice.isPad() && traitCollection.horizontalSizeClass != .compact
    }
}
