import UIKit

extension UINavigationController {
    func scrollContentToTopAnimated(_ animated: Bool) {
        guard viewControllers.count == 1 else { return }

        if let topViewController = topViewController as? WPScrollableViewController {
            topViewController.scrollViewToTop()
        } else if let scrollView = topViewController?.view as? UIScrollView {
            let offset = CGPoint(x: 0, y: -scrollView.contentInset.top)
            scrollView.setContentOffset(offset, animated: animated)
        }
    }
}
