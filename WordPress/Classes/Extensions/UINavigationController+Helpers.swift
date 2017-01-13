import UIKit

extension UINavigationController {
    func scrollContentToTopAnimated(_ animated: Bool) {
        guard viewControllers.count == 1 else { return }

        if let topViewController = topViewController as? WPScrollableViewController {
            topViewController.scrollViewToTop()
        } else if let scrollView = topViewController?.view as? UIScrollView {
            // If the view controller's view is a scrollview
            let offset = CGPoint(x: 0, y: -scrollView.contentInset.top)
            scrollView.setContentOffset(offset, animated: animated)
        } else if let scrollViews = topViewController?.view.subviews.filter({ $0 is UIScrollView }) as? [UIScrollView] {
            // If one of the top level views of the view controller's view
            // is a scrollview
            if let scrollView = scrollViews.first {
                let offset = CGPoint(x: 0, y: -scrollView.contentInset.top)
                scrollView.setContentOffset(offset, animated: animated)
            }
        }
    }
}
