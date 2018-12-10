import Foundation


protocol RevisionDiffsPageManagerDelegate: class {
    func currentIndex() -> Int
    func pageWillScroll(to direction: UIPageViewController.NavigationDirection)
    func pageDidFinishAnimating(completed: Bool)
}


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
        return getViewController(at: index(of: viewController),
                                 direction: .reverse,
                                 operation: -)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return getViewController(at: index(of: viewController),
                                 direction: .forward,
                                 operation: +)
    }

    private func getViewController(at index: Int?, direction: UIPageViewController.NavigationDirection, operation: (Int, Int) -> Int) -> UIViewController? {
        guard let index = index else {
            return nil
        }

        let nextIndex = operation(index, 1)
        let count = viewControllers.count

        switch direction {
        case .forward:
            if count == nextIndex || count < nextIndex {
                return nil
            }
        case .reverse:
            if nextIndex < 0 || count < nextIndex {
                return nil
            }
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
