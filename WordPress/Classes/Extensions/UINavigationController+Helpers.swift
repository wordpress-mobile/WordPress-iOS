import UIKit

extension UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override open var childForStatusBarStyle: UIViewController? {
        if let _ = topViewController as? DefinesVariableStatusBarStyle {
            return topViewController
        }
        return nil
    }

    @objc func scrollContentToTopAnimated(_ animated: Bool) {
        guard viewControllers.count == 1 else { return }

        let scrollToTop = { (scrollView: UIScrollView) in
            let offset = CGPoint(x: 0, y: -scrollView.contentInset.top)
            scrollView.setContentOffset(offset, animated: animated)
        }

        if let topViewController = topViewController as? WPScrollableViewController {
            topViewController.scrollViewToTop()
        } else if let scrollView = topViewController?.view as? UIScrollView {
            // If the view controller's view is a scrollview
            scrollToTop(scrollView)
        } else if let scrollViews = topViewController?.view.subviews.filter({ $0 is UIScrollView }) as? [UIScrollView] {
            // If one of the top level views of the view controller's view
            // is a scrollview
            if let scrollView = scrollViews.first {
                scrollToTop(scrollView)
            }
        }
    }

    /// Fixes a crash in iOS 13 (#12882) where presenting a UIDocumentMenuViewController in a webView
    /// doesn't rautomattically ecognize the location for presenting the menu hence the crash.
    /// The warning is probably a bug on iOS or on WebKit since replacing with UIDocumentPickerViewController doesn't prevent the crash.
    ///
    @objc override open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if #available(iOS 13, *), UIDevice.current.userInterfaceIdiom == .phone,
            let webKitVC = topViewController as? WebKitViewController,
            viewControllerToPresent is UIDocumentMenuViewController {
            viewControllerToPresent.popoverPresentationController?.delegate = webKitVC
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}
