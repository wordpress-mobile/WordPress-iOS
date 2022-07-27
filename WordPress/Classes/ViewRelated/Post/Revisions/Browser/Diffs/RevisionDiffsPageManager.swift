import Foundation


protocol RevisionDiffsPageManagerDelegate: AnyObject {
    func currentIndex() -> Int
    func pageWillScroll(to direction: UIPageViewController.NavigationDirection)
    func pageDidFinishAnimating(completed: Bool)
}

// Delegate and data source of the page view controller used
// by the RevisionDiffsBrowserViewController
//
class RevisionDiffsPageManager: NSObject {
    var viewControllers: [RevisionDiffViewController] = []

    private unowned var delegate: RevisionDiffsPageManagerDelegate

    init(delegate: RevisionDiffsPageManagerDelegate) {
        self.delegate = delegate
    }

    private func index(of viewController: UIViewController?) -> Int? {
        return viewControllers.lazy.firstIndex { $0 === viewController }
    }
}


extension RevisionDiffsPageManager: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = index(of: viewController) else {
            return nil
        }
        return getViewController(at: index, direction: .reverse)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = index(of: viewController) else {
            return nil
        }
        return getViewController(at: index, direction: .forward)
    }

    private func getViewController(at index: Int, direction: UIPageViewController.NavigationDirection) -> UIViewController? {
        var nextIndex = 0
        let count = viewControllers.count

        switch direction {
        case .forward:
            nextIndex = index + 1
            if count == nextIndex || count < nextIndex {
                return nil
            }
        case .reverse:
            nextIndex = index - 1
            if nextIndex < 0 || count < nextIndex {
                return nil
            }
        @unknown default:
            fatalError()
        }

        return viewControllers[nextIndex]
    }
}


extension RevisionDiffsPageManager: UIPageViewControllerDelegate {
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return viewControllers.count
    }

    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return delegate.currentIndex()
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        delegate.pageDidFinishAnimating(completed: completed)
    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        let currentIndex = delegate.currentIndex()
        guard let viewControllerIndex = index(of: pendingViewControllers.first),
            currentIndex != viewControllerIndex  else {
                return
        }

        let direction: UIPageViewController.NavigationDirection = currentIndex > viewControllerIndex ? .reverse : .forward
        delegate.pageWillScroll(to: direction)
    }
}
