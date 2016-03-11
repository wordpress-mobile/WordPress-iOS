import UIKit
import WordPressShared

class PlanComparisonViewController: UIViewController {
    private let embedIdentifier = "PageViewControllerEmbedSegue"
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var planStackView: UIStackView!
    
    var activePlan: Plan?
    
    var currentPlan: Plan = defaultPlans[0] {
        didSet {
            if currentPlan != oldValue {
                updateForCurrentPlan()
            }
        }
    }

    private var currentIndex: Int {
        return allPlans.indexOf(currentPlan) ?? 0
    }
    
    private lazy var viewControllers: [PlanDetailViewController] = {
        return self.allPlans.map { plan in
            let controller = PlanDetailViewController.controllerWithPlan(plan)
            if let activePlan = self.activePlan {
                controller.isActivePlan = activePlan == plan
            }
            
            return controller
        }
    }()
    
    private let allPlans = defaultPlans
    
    lazy private var cancelXButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "gridicons-cross"), style: .Plain, target: self, action: "closeTapped")
        button.accessibilityLabel = NSLocalizedString("Close", comment: "Dismiss the current view")
        
        return button
    }()
    
    class func controllerWithInitialPlan(plan: Plan, activePlan: Plan? = nil) -> PlanComparisonViewController {
        let storyboard = UIStoryboard(name: "Plans", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier(NSStringFromClass(self)) as! PlanComparisonViewController

        controller.activePlan = activePlan
        controller.currentPlan = plan
        
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = WPStyleGuide.greyLighten30()
        divider.backgroundColor = WPStyleGuide.greyLighten20()
        pageControl.currentPageIndicatorTintColor = WPStyleGuide.grey()
        pageControl.pageIndicatorTintColor = WPStyleGuide.grey().colorWithAlphaComponent(0.5)
        
        navigationItem.leftBarButtonItem = cancelXButton
        
        initializePlanDetailViewControllers()
        updateForCurrentPlan()
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

    func initializePlanDetailViewControllers() {
        for controller in viewControllers {
            addChildViewController(controller)
            
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            planStackView.addArrangedSubview(controller.view)
            
            controller.view.shouldGroupAccessibilityChildren = true
            controller.view.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 1.0).active = true
            controller.view.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
            controller.view.bottomAnchor.constraintEqualToAnchor(divider.topAnchor).active = true
            
            controller.didMoveToParentViewController(self)
        }
    }
    
    func updateForCurrentPlan() {
        title = currentPlan.title
        
        updatePageControl()
        
        for (index, viewController) in viewControllers.enumerate() {
            viewController.view.accessibilityElementsHidden = index != currentIndex
        }
    }
    
    
    // MARK: - IBActions
    
    @IBAction private func closeTapped() {
        dismissViewControllerAnimated(true, completion: nil)
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
    
    private func updatePageControl() {
        pageControl?.currentPage = currentIndex
    }
}

extension PlanComparisonViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // Ignore programmatic scrolling
        if scrollView.dragging {
            currentPlan = allPlans[currentScrollViewPage()]
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
            accessibilityAnnounceCurrentPlan()
        }
        
        return success
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        scrollView.userInteractionEnabled = true
        
        accessibilityAnnounceCurrentPlan()
    }
    
    private func accessibilityAnnounceCurrentPlan() {
        let currentViewController = viewControllers[currentIndex]
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, currentViewController.planTitleLabel)
    }
    
    private func currentScrollViewPage() -> Int {
        // Calculate which plan's VC is at the center of the view
        let pageWidth = scrollView.bounds.width
        let centerX = scrollView.contentOffset.x + (pageWidth / 2)
        let currentPage = Int(floor(centerX / pageWidth))

        // Keep it within bounds
        return currentPage.clamp(min: 0, max: allPlans.count - 1)
    }

    /// @return True if there was valid page to scroll to, false if we've reached the beginning / end
    private func scrollToPage(page: Int, animated: Bool) -> Bool {
        guard allPlans.indices.contains(page) else { return false }
        
        let pageWidth = view.bounds.width
        scrollView.setContentOffset(CGPoint(x: CGFloat(page) * pageWidth, y: 0), animated: animated)
    
        currentPlan = allPlans[page]
        
        return true
    }
}
