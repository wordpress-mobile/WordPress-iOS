import UIKit
import WordPressShared

class PagedViewController: UIViewController {
    @IBOutlet weak var pagedStackView: UIStackView!
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var pageControlContainer: UIView!

    @objc let viewControllers: [UIViewController]
    @objc var currentIndex: Int = 0 {
        didSet {
            if currentIndex != oldValue {
                updateForCurrentIndex()
            }
        }
    }

    @objc init(viewControllers: [UIViewController], initialIndex: Int) {
        precondition(viewControllers.indices.contains(initialIndex))

        self.viewControllers = viewControllers
        self.currentIndex = initialIndex
        super.init(nibName: "PagedViewController", bundle: Bundle(for: PagedViewController.self))
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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // If the view is changing size (e.g. on rotation, or multitasking), scroll to the correct page boundary based on the new size
        coordinator.animate(alongsideTransition: { context in
            self.scrollView.setContentOffset(CGPoint(x: CGFloat(self.currentIndex) * size.width, y: 0), animated: false)
        })
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollToPage(currentIndex, animated: false)
    }

    fileprivate func applyWPStyles() {
        view.backgroundColor = .listBackground
        pageControlContainer.backgroundColor = .listBackground

        divider.heightAnchor.constraint(equalToConstant: .hairlineBorderWidth).isActive = true
        divider.backgroundColor = .divider

        pageControl.currentPageIndicatorTintColor = .listSmallIcon
        pageControl.pageIndicatorTintColor = UIColor.listSmallIcon.withAlphaComponent(0.5)
    }

    fileprivate func addViewControllers() {
        for controller in viewControllers {
            addChild(controller)

            controller.view.translatesAutoresizingMaskIntoConstraints = false
            pagedStackView.addArrangedSubview(controller.view)

            controller.view.shouldGroupAccessibilityChildren = true
            controller.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0).isActive = true
            controller.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            controller.view.bottomAnchor.constraint(equalTo: divider.topAnchor).isActive = true

            controller.didMove(toParent: self)
        }

        pageControl.numberOfPages = viewControllers.count
    }

    @IBAction func pageControlChanged() {
        guard !scrollView.isDragging else {
            // If the user is currently dragging, reset the change and ignore it
            pageControl.currentPage = currentIndex
            return
        }

        // Stop the user interacting whilst we animate a scroll
        scrollView.isUserInteractionEnabled = false

        var targetPage = currentIndex
        if pageControl.currentPage > currentIndex {
            targetPage += 1
        } else if pageControl.currentPage < currentIndex {
            targetPage -= 1
        }

        scrollToPage(targetPage, animated: true)
    }

    fileprivate func updateForCurrentIndex() {
        title = currentViewController.title

        updatePageControl()

        for (index, viewController) in viewControllers.enumerated() {
            viewController.view.accessibilityElementsHidden = index != currentIndex
        }
    }

    fileprivate func updatePageControl() {
        pageControl?.currentPage = currentIndex
    }

    fileprivate var currentViewController: UIViewController {
        return viewControllers[currentIndex]
    }
}

extension PagedViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Ignore programmatic scrolling
        if scrollView.isDragging {
            currentIndex = currentScrollViewPage()
        }
    }

    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        var targetPage = currentIndex

        switch direction {
        case .right: targetPage -= 1
        case .left: targetPage += 1
        default: break
        }

        let success = scrollToPage(targetPage, animated: false)
        if success {
            accessibilityAnnounceCurrentPage()
        }

        return success
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollView.isUserInteractionEnabled = true

        accessibilityAnnounceCurrentPage()
    }

    fileprivate func accessibilityAnnounceCurrentPage() {
        UIAccessibility.post(notification: .layoutChanged, argument: currentViewController.view)
    }

    fileprivate func currentScrollViewPage() -> Int {
        // Calculate which plan's VC is at the center of the view
        let pageWidth = scrollView.bounds.width
        let centerX = scrollView.contentOffset.x + (pageWidth / 2)
        let currentPage = rtlCorrectedPage(Int(floor(centerX / pageWidth)))

        // Keep it within bounds
        return currentPage.clamp(min: 0, max: viewControllers.count - 1)
    }

    /// - Returns: True if there was valid page to scroll to, false if we've reached the beginning / end
    @discardableResult fileprivate func scrollToPage(_ page: Int, animated: Bool) -> Bool {
        guard viewControllers.indices.contains(page) else { return false }

        let pageWidth = view.bounds.width
        scrollView.setContentOffset(CGPoint(x: CGFloat(rtlCorrectedPage(page)) * pageWidth, y: 0), animated: animated)

        currentIndex = page

        return true
    }

    fileprivate func rtlCorrectedPage(_ page: Int) -> Int {
        if view.userInterfaceLayoutDirection() == .leftToRight {
            return page
        } else {
            return viewControllers.count - page - 1
        }
    }
}
