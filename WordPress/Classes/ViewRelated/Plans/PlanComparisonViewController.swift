import UIKit
import WordPressShared

class PlanComparisonViewController: UIViewController {
    private let embedIdentifier = "PageViewControllerEmbedSegue"
    
    var pageViewController: UIPageViewController!
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var divider: UIView!
    
    var currentPlan: Plan = .Free {
        didSet {
            title = currentPlan.title
            
            updatePageControl()
        }
    }
    
    private var currentIndex: Int? {
        return allPlans.indexOf(currentPlan)
    }
    
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
        
        updatePageControl()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if let pageViewController = segue.destinationViewController as? UIPageViewController where segue.identifier == embedIdentifier {
            self.pageViewController = pageViewController
            
            configurePageViewController()
        }
    }
    
    // MARK: - IBActions
    
    @IBAction private func closeTapped() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func pageControlChanged() {
        guard let index = currentIndex else { return }
        
        if pageControl.currentPage > index {
            scrollToNextPage() { success in
                if success {
                    self.currentPlan = self.allPlans[index + 1]
                }
            }
        } else if pageControl.currentPage < index {
            scrollToPreviousPage() { success in
                if success {
                    self.currentPlan = self.allPlans[index - 1]
                }
            }
        }
    }

    // MARK: - PageViewController
    private func configurePageViewController() {
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        if let index = currentIndex,
            let initialViewController = viewControllerAtIndex(index) {
                
            pageViewController.setViewControllers([initialViewController], direction: .Forward, animated: false, completion: nil)
        }
    }
    
    private func viewControllerAtIndex(index: Int) -> UIViewController? {
        guard index >= 0 && index < allPlans.count  else {
            return nil
        }
        
        let plan = allPlans[index]
        return PlanDetailViewController.controllerWithPlan(plan)
    }
    
    private func indexOfViewController(viewController: PlanDetailViewController) -> Int {
        let plan = viewController.plan
        return allPlans.indexOf(plan)!
    }
    
    private func updatePageControl() {
        if let index = currentIndex {
            pageControl?.currentPage = index
        }
    }
}

extension PlanComparisonViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        return previousViewController()
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        return nextViewController()
    }
    
    private func previousViewController() -> UIViewController? {
        guard let index = currentIndex else { return nil }
        
        return viewControllerAtIndex(index - 1)
    }
    
    private func nextViewController() -> UIViewController? {
        guard let index = currentIndex else { return nil }
        
        return viewControllerAtIndex(index + 1)
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let controller = pageViewController.viewControllers?.first as? PlanDetailViewController {
            currentPlan = allPlans[indexOfViewController(controller)]
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, currentPlan.title)
        }
    }

    /// `success` is if the scrolling action was successful (i.e. there was a page to scroll to)
    private func scrollToNextPage(completion: ((success: Bool) -> ())? = nil) {
        guard let nextViewController = nextViewController() else {
            completion?(success: false)
            return
        }
        
        pageViewController.setViewControllers([nextViewController], direction: .Forward, animated: true, completion: nil)
        completion?(success: true)
    }
    
    /// `success` is true if the scrolling action was successful (i.e. there was a page to scroll to)
    private func scrollToPreviousPage(completion: ((success: Bool) -> ())? = nil) {
        guard let previousViewController = previousViewController() else {
            completion?(success: false)
            return
        }
        
        pageViewController.setViewControllers([previousViewController], direction: .Reverse, animated: true, completion: nil)
        completion?(success: true)
    }
}
