import UIKit

protocol SiteMediaPageViewControllerDelegate: AnyObject {
    func siteMediaPageViewController(_ viewController: SiteMediaPageViewController, getMediaBeforeMedia media: Media) -> Media?
    func siteMediaPageViewController(_ viewController: SiteMediaPageViewController, getMediaAfterMedia media: Media) -> Media?
}

final class SiteMediaPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    private weak var siteMediaDelegate: SiteMediaPageViewControllerDelegate?

    init(media: Media, delegate: SiteMediaPageViewControllerDelegate) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
        siteMediaDelegate = delegate

        dataSource = self
        self.delegate = self

        let page = makePageViewController(with: media)
        setViewControllers([page], direction: .forward, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        updateNavigationForCurrentViewController()
    }

    private func makePageViewController(with media: Media) -> MediaItemViewController {
        MediaItemViewController(media: media)
    }

    // MARK: - UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let current = (viewController as! MediaItemViewController).media
        guard let media = siteMediaDelegate?.siteMediaPageViewController(self, getMediaBeforeMedia: current) else {
            return nil
        }
        return makePageViewController(with: media)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let current = (viewController as! MediaItemViewController).media
        guard let media = siteMediaDelegate?.siteMediaPageViewController(self, getMediaAfterMedia: current) else {
            return nil
        }
        return makePageViewController(with: media)
    }

    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        updateNavigationForCurrentViewController()
    }

    private func updateNavigationForCurrentViewController() {
        if let viewController = viewControllers?.first {
            navigationItem.title = viewController.title
            navigationItem.rightBarButtonItems = viewController.navigationItem.rightBarButtonItems
        }
    }
}
