import UIKit

extension UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return WPStyleGuide.preferredStatusBarStyle
    }

    override open var childForStatusBarStyle: UIViewController? {
        if let _ = topViewController as? DefinesVariableStatusBarStyle {
            return topViewController
        }
        return nil
    }

    @objc func scrollContentToTopAnimated(_ animated: Bool) {
        guard viewControllers.count == 1 else { return }

        if let topViewController = topViewController as? WPScrollableViewController {
            topViewController.scrollViewToTop()
        } else if let scrollView = topViewController?.view as? UIScrollView {
            // If the view controller's view is a scrollview
            scrollView.scrollToTop(animated: animated)
        } else if let scrollViews = topViewController?.view.subviews.filter({ $0 is UIScrollView }) as? [UIScrollView] {
            // If one of the top level views of the view controller's view
            // is a scrollview
            if let scrollView = scrollViews.first {
                scrollView.scrollToTop(animated: animated)
            }
        }
    }

    /// Fixes a crash in iOS 13 (#12882) where presenting a UIDocumentMenuViewController in a webView
    /// doesn't automattically ecognize the location for presenting the menu hence the crash.
    /// If this issue is addressed by Apple in following release we can remove this override.
    ///
    @objc override open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if UIDevice.current.userInterfaceIdiom == .phone,
           let webKitVC = topViewController as? WebKitViewController {
            viewControllerToPresent.popoverPresentationController?.delegate = webKitVC
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    /// Adds an optional right bar button to a UIViewController instance pushed on the navigation stack
    /// - Parameters:
    ///   - viewController: the UIViewController instance to push on the navigation stack
    ///   - animated: true if the push is animated
    ///   - rightBarButton: optional right bar button
    func pushViewController(_ viewController: UIViewController, animated: Bool, rightBarButton: UIBarButtonItem?) {
        viewController.navigationItem.rightBarButtonItem = rightBarButton
        self.pushViewController(viewController, animated: animated)
    }
}

extension UIViewController {
    func configureDefaultNavigationBarAppearance() {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()

        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()

        navigationItem.standardAppearance = standardAppearance
        navigationItem.compactAppearance = standardAppearance
        navigationItem.scrollEdgeAppearance = scrollEdgeAppearance
        navigationItem.compactScrollEdgeAppearance = scrollEdgeAppearance
    }
}
