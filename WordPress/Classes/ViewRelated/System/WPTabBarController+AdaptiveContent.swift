import UIKit

extension WPTabBarController {
    @objc func observeAdaptiveTabBarTraits() {
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) {
            (controller: WPTabBarController, _: UITraitCollection) in
            controller.updateAdaptiveTabBarVisibility(animated: false)
        }
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
