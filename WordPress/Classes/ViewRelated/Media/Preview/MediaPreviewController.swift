import UIKit

protocol MediaPreviewControllerDataSource: AnyObject {
    func numberOfPreviewItems(in controller: MediaPreviewController) -> Int
    func previewController(_ controller: MediaPreviewController, previewItemAt index: Int) -> MediaPreviewItem
}

struct MediaPreviewItem {
    let url: URL
}

/// Allows you to preview media fullscreen.
final class MediaPreviewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    weak var dataSource: MediaPreviewControllerDataSource?

    /// Sets the initial index of the preview item.
    var currentPreviewItemIndex = 0
    private var numberOfItems: Int = 0

    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItems()
        configurePageViewController()
        updateNavigationForCurrentViewController()
    }

    private func configureNavigationItems() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: .init { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        })
    }

    private func configurePageViewController() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(pageViewController.view)

        pageViewController.dataSource = self
        pageViewController.delegate = self

        reloadData()
    }

    private func reloadData() {
        numberOfItems = dataSource?.numberOfPreviewItems(in: self) ?? 0
        if let page = makePageViewController(at: currentPreviewItemIndex) {
            pageViewController.setViewControllers([page], direction: .forward, animated: false)
        }
    }

    private func makePageViewController(at index: Int) -> MediaPreviewItemViewController? {
        guard index >= 0 && index < numberOfItems,
              let item = dataSource?.previewController(self, previewItemAt: index) else {
            return nil
        }
        let viewController = MediaPreviewItemViewController(externalMediaURL: item.url)
        viewController.shouldDismissWithGestures = false
        viewController.index = index
        return viewController
    }

    // MARK: - UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = (viewController as! MediaPreviewItemViewController).index
        return makePageViewController(at: index - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = (viewController as! MediaPreviewItemViewController).index
        return makePageViewController(at: index + 1)
    }

    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        updateNavigationForCurrentViewController()
    }

    private func updateNavigationForCurrentViewController() {
        guard let viewController = pageViewController.viewControllers?.first as? MediaPreviewItemViewController else {
            return
        }
        navigationItem.title = String(format: Strings.title, String(viewController.index + 1), String(numberOfItems))
    }
}

private final class MediaPreviewItemViewController: WPImageViewController {
    var index = 0
}

private enum Strings {
    static let title = NSLocalizedString("mediaPreview.NofM", value: "%@ of %@", comment: "Navigation title for media preview. Example: 1 of 3")
}
