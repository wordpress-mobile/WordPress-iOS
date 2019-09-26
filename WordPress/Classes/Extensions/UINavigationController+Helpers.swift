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
}
