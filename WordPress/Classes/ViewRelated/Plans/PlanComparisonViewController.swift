import UIKit
import WordPressShared

class PlanComparisonViewController: UIViewController {
    private let embedIdentifier = "PageViewControllerEmbedSegue"
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var planStackView: UIStackView!
    
    var currentPlan: Plan = .Free {
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
        return self.allPlans.map { PlanDetailViewController.controllerWithPlan($0) }
    }()
    
    private let allPlans = [Plan.Free, Plan.Premium, Plan.Business]
    
    lazy private var cancelXButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "gridicons-cross"), style: .Plain, target: self, action: "closeTapped")
        button.accessibilityLabel = NSLocalizedString("Close", comment: "Dismiss the current view")
        
        return button
    }()
    
    class func controllerWithInitialPlan(plan: Plan) -> PlanComparisonViewController {
        let storyboard = UIStoryboard(name: "Plans", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier(NSStringFromClass(self)) as! PlanComparisonViewController
        
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
            self.scrollView.setContentOffset(CGPoint(x: CGFloat(self.currentIndex) * size.width, y: 0), animated: true)
        }, completion: nil)
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
            
            controller.view.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 1.0).active = true
            controller.view.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
            controller.view.bottomAnchor.constraintEqualToAnchor(divider.topAnchor).active = true
            
            controller.didMoveToParentViewController(self)
        }
    }
    
    func updateForCurrentPlan() {
        title = currentPlan.title
        
        updatePageControl()
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
        
        if allPlans.indices.contains(targetPage) {
            scrollToPage(targetPage, animated: true)
            currentPlan = allPlans[targetPage]
        }
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
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        scrollView.userInteractionEnabled = true
        
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, currentPlan.title)
    }
    
    private func currentScrollViewPage() -> Int {
        // Calculate which plan's VC is at the center of the view
        let pageWidth = scrollView.bounds.width
        let centerX = scrollView.contentOffset.x + (pageWidth / 2)
        let currentPage = Int(floor(centerX / pageWidth))

        // Keep it within bounds
        return max(min(currentPage, allPlans.count - 1), 0)
    }
    
    private func scrollToPage(page: Int, animated: Bool) {
        let pageWidth = view.bounds.width
        
        scrollView.setContentOffset(CGPoint(x: CGFloat(page) * pageWidth, y: 0), animated: animated)
    }
}
