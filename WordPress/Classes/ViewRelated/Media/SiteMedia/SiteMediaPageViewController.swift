import UIKit

protocol SiteMediaPageViewControllerDelegate: AnyObject {
    func siteMediaPageViewController(_ viewController: SiteMediaPageViewController, getMediaBeforeMedia media: Media) -> Media?
    func siteMediaPageViewController(_ viewController: SiteMediaPageViewController, getMediaAfterMedia media: Media) -> Media?
}

final class SiteMediaPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    private weak var siteMediaDelegate: SiteMediaPageViewControllerDelegate?
    private var prefetchingTask: Task<Void, Error>?

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

        view.backgroundColor = .systemBackground
        updateNavigationForCurrentViewController()
    }

    func didDeleteItem(_ media: Media, before: Media?, after: Media?) {
        guard let viewController = viewControllers?.first as? MediaItemViewController,
              viewController.media == media else {
            return
        }
        func showAdjacentPage() {
            if let before {
                setViewControllers([makePageViewController(with: before)], direction: .reverse, animated: true, completion: nil)
                updateNavigationForCurrentViewController()
            } else if let after {
                setViewControllers([makePageViewController(with: after)], direction: .forward, animated: true, completion: nil)
                updateNavigationForCurrentViewController()
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
        if let cell = viewController.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
            UIView.animate(withDuration: 0.4) {
                cell.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                cell.alpha = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                showAdjacentPage()
            }
        } else {
            showAdjacentPage()
        }
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
        if let previous = siteMediaDelegate?.siteMediaPageViewController(self, getMediaBeforeMedia: media) {
            startPrefetching(for: previous)
        }
        return makePageViewController(with: media)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let current = (viewController as! MediaItemViewController).media
        guard let media = siteMediaDelegate?.siteMediaPageViewController(self, getMediaAfterMedia: current) else {
            return nil
        }
        if let next = siteMediaDelegate?.siteMediaPageViewController(self, getMediaAfterMedia: media) {
            startPrefetching(for: next)
        }
        return makePageViewController(with: media)
    }

    private func startPrefetching(for media: Media) {
        if let task = prefetchingTask {
            // Give the task a chance to complete and/or the new task
            // to subscrive to the underlying network task
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                task.cancel()
            }
        }
        guard media.mediaType == .image else { return }
        prefetchingTask = Task {
            _ = try await MediaImageService.shared.image(for: media, size: .large)
        }
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
