import UIKit
import WordPressShared

class PagedViewController: UIViewController {
    @IBOutlet weak var pagedStackView: UIStackView!
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!

    let viewControllers: [UIViewController]
    var currentIndex: Int = 0 {
        didSet {
            if currentIndex != oldValue {
                updateForCurrentIndex()
            }
        }
    }

    init(viewControllers: [UIViewController], initialIndex: Int) {
        precondition(viewControllers.indices.contains(initialIndex))

        self.viewControllers = viewControllers
        self.currentIndex = initialIndex
        super.init(nibName: "PagedViewController", bundle: NSBundle(forClass: PagedViewController.self))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyWPStyles()
        addViewControllers()
        updateForCurrentIndex()
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        // If the view is changing size (e.g. on rotation, or multitasking), scroll to the correct page boundary based on the new size
        coordinator.animateAlongsideTransition({ context in
            self.scrollView.setContentOffset(CGPoint(x: CGFloat(self.currentIndex) * size.width, y: 0), animated: false)
            }, completion: nil)
    }

    override func shouldAutorotate() -> Bool {
        return false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollToPage(currentIndex, animated: false)
    }

    private func applyWPStyles() {
        view.backgroundColor = WPStyleGuide.greyLighten30()
        divider.backgroundColor = WPStyleGuide.greyLighten30()
        pageControl.currentPageIndicatorTintColor = WPStyleGuide.grey()
        pageControl.pageIndicatorTintColor = WPStyleGuide.grey().colorWithAlphaComponent(0.5)
    }

    private func addViewControllers() {
        for controller in viewControllers {
            addChildViewController(controller)

            controller.view.translatesAutoresizingMaskIntoConstraints = false
            pagedStackView.addArrangedSubview(controller.view)

            controller.view.shouldGroupAccessibilityChildren = true
            controller.view.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 1.0).active = true
            controller.view.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
            controller.view.bottomAnchor.constraintEqualToAnchor(divider.topAnchor).active = true

            controller.didMoveToParentViewController(self)
        }
    }

    @IBAction func pageControlChanged() {
        guard !scrollView.dragging else {
            // If the user is currently dragging, reset the change and ignore it
            pageControl.currentPage = currentIndex
            return
        }

        // Stop the user interacting whilst we animate a scroll
        scrollView.userInteractionEnabled = false

        var targetPage = currentIndex
        if pageControl.currentPage > currentIndex {
            targetPage += 1
        } else if pageControl.currentPage < currentIndex {
            targetPage -= 1
        }

        scrollToPage(targetPage, animated: true)
    }

    private func updateForCurrentIndex() {
        title = currentViewController.title

        updatePageControl()

        for (index, viewController) in viewControllers.enumerate() {
            viewController.view.accessibilityElementsHidden = index != currentIndex
        }
    }

    private func updatePageControl() {
        pageControl?.currentPage = currentIndex
    }

    private var currentViewController: UIViewController {
        return viewControllers[currentIndex]
    }
}

extension PagedViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // Ignore programmatic scrolling
        if scrollView.dragging {
            currentIndex = currentScrollViewPage()
        }
    }

    override func accessibilityScroll(direction: UIAccessibilityScrollDirection) -> Bool {
        var targetPage = currentIndex

        switch direction {
        case .Right: targetPage -= 1
        case .Left: targetPage += 1
        default: break
        }

        let success = scrollToPage(targetPage, animated: false)
        if success {
            accessibilityAnnounceCurrentPage()
        }

        return success
    }

    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        scrollView.userInteractionEnabled = true

        accessibilityAnnounceCurrentPage()
    }

    private func accessibilityAnnounceCurrentPage() {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, currentViewController.view)
    }

    private func currentScrollViewPage() -> Int {
        // Calculate which plan's VC is at the center of the view
        let pageWidth = scrollView.bounds.width
        let centerX = scrollView.contentOffset.x + (pageWidth / 2)
        let currentPage = Int(floor(centerX / pageWidth))

        // Keep it within bounds
        return currentPage.clamp(min: 0, max: viewControllers.count - 1)
    }

    /// - Returns: True if there was valid page to scroll to, false if we've reached the beginning / end
    private func scrollToPage(page: Int, animated: Bool) -> Bool {
        guard viewControllers.indices.contains(page) else { return false }

        let pageWidth = view.bounds.width
        scrollView.setContentOffset(CGPoint(x: CGFloat(page) * pageWidth, y: 0), animated: animated)

        currentIndex = page

        return true
    }
}
