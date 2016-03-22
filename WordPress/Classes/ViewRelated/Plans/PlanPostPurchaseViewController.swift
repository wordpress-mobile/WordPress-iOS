import UIKit
import WordPressShared

class PlanPostPurchaseViewController: UIViewController {

    private let pageControlHeight: CGFloat = 59
    private let contentTopInset: CGFloat = 25
    private var headingParallaxMaxTranslation: CGFloat = 200
    private var descriptionParallaxMaxTranslation: CGFloat = 100
    
    private weak var pageControl: UIPageControl!
    private weak var scrollView: UIScrollView!
    
    var pageTypes: [PlanPostPurchasePageType]!
    var pages = [PlanPostPurchasePageViewController]()
    var plan: Plan

    lazy private var cancelXButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "gridicons-cross"), style: .Plain, target: self, action: #selector(PlanPostPurchaseViewController.closeTapped))
        button.accessibilityLabel = NSLocalizedString("Close", comment: "Dismiss the current view")
        
        return button
    }()
    
    init(plan: Plan) {
        pageTypes = PlanPostPurchasePageType.pageTypesForPlan(plan)
        self.plan = plan
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = WPStyleGuide.wordPressBlue()

        navigationItem.leftBarButtonItem = cancelXButton

        addPageControl()
        addScrollView()
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        // If the view is changing size (e.g. on rotation, or multitasking), scroll to the correct page boundary based on the new size
        coordinator.animateAlongsideTransition({ context in
            self.scrollView.setContentOffset(CGPoint(x: CGFloat(self.currentScrollViewPage()) * size.width, y: 0), animated: true)
            }, completion: nil)
    }
    
    private func addPageControl() {
        let pageControl = UIPageControl()
        view.addSubview(pageControl)
        
        pageControl.tintColor = UIColor.whiteColor()
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        pageControl.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        pageControl.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        pageControl.heightAnchor.constraintEqualToConstant(pageControlHeight).active = true
        
        pageControl.addTarget(self, action: #selector(PlanPostPurchaseViewController.pageControlChanged), forControlEvents: .ValueChanged)
        self.pageControl = pageControl
    }
    
    private func addScrollView() {
        let scrollView = UIScrollView()
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.backgroundColor = WPStyleGuide.wordPressBlue()
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        scrollView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        scrollView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        scrollView.bottomAnchor.constraintEqualToAnchor(pageControl.topAnchor).active = true
        
        let container = UIStackView()
        container.axis = .Horizontal
        scrollView.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        scrollView.pinSubviewToAllEdges(container)
        
        for pageType in pageTypes {
            addNewPageViewControllerForPageType(pageType, toContainer: container)
        }
        
        pageControl.numberOfPages = pages.count
        
        container.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: CGFloat(pages.count))
        
        self.scrollView = scrollView
    }
    
    private func addNewPageViewControllerForPageType(pageType: PlanPostPurchasePageType, toContainer container: UIStackView) {
        let page = PlanPostPurchasePageViewController.controller()
        addChildViewController(page)
        
        page.view.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(page.view)
        
        page.view.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
        page.view.bottomAnchor.constraintEqualToAnchor(pageControl.topAnchor).active = true
        
        page.didMoveToParentViewController(self)
        
        page.plan = plan
        page.pageType = pageType
        page.view.accessibilityElementsHidden = (pageType != .PurchaseComplete)
        page.view.shouldGroupAccessibilityChildren = true

        pages.append(page)
    }
    
    @IBAction func pageControlChanged() {
        let currentIndex = currentScrollViewPage()
        
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
    
    func closeTapped() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension PlanPostPurchaseViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let pageWidth = scrollView.bounds.width
        
        guard pageWidth > 0 else { return }
        
        let centerX = scrollView.contentOffset.x + (pageWidth / 2)
        let currentPageFraction = (centerX / pageWidth)
        let currentPageIndex = Int(floor(currentPageFraction))
        
        for (index, page) in pages.enumerate() {
            let pageCenter = CGFloat(index) + 0.5
            let offset = currentPageFraction - pageCenter
            
            page.headingLabel.transform = CGAffineTransformMakeTranslation(offset * -headingParallaxMaxTranslation, 0)
            page.descriptionLabel.transform = CGAffineTransformMakeTranslation(offset * -descriptionParallaxMaxTranslation, 0)
        }
        
        if scrollView.dragging {
            pageControl.currentPage = currentPageIndex
        }
    }

    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        scrollView.userInteractionEnabled = true
    }
    
    override func accessibilityScroll(direction: UIAccessibilityScrollDirection) -> Bool {
        var targetPage = currentScrollViewPage()
        
        switch direction {
        case .Right: targetPage -= 1
        case .Left: targetPage += 1
        default: break
        }
        
        let success = scrollToPage(targetPage, animated: false)
        if success {
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
        }
        
        return success
    }
    
    private func currentScrollViewPage() -> Int {
        // Calculate which plan's VC is at the center of the view
        let pageWidth = scrollView.bounds.width
        let centerX = scrollView.contentOffset.x + (pageWidth / 2)
        let currentPage = Int(floor(centerX / pageWidth))
        
        // Keep it within bounds
        return currentPage.clamp(min: 0, max: pages.count - 1)
    }
    
    /// - returns: True if there was valid page to scroll to, false if we've reached the beginning / end
    private func scrollToPage(page: Int, animated: Bool) -> Bool {
        guard pages.indices.contains(page) else { return false }
        
        let pageWidth = view.bounds.width
        scrollView.setContentOffset(CGPoint(x: CGFloat(page) * pageWidth, y: 0), animated: animated)

        for (index, pageVC) in pages.enumerate() {
            pageVC.view.accessibilityElementsHidden = (index != page)
        }

        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
        
        return true
    }
}

class PlanPostPurchasePageViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    let purchaseCompleteImageViewSize: CGFloat = 90
    
    var plan: Plan?
    var pageType: PlanPostPurchasePageType? = nil {
        didSet {
            populateViews()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        view.backgroundColor = WPStyleGuide.wordPressBlue()
        actionButton.tintColor = WPStyleGuide.wordPressBlue()
        
        view.shouldGroupAccessibilityChildren = true
    }
    
    class func controller() -> PlanPostPurchasePageViewController {
        let storyboard = UIStoryboard(name: "Plans", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier(NSStringFromClass(self)) as! PlanPostPurchasePageViewController
        
        return controller
    }
    
    func setDescriptionText(text: String) {
        let lineHeight: CGFloat = 21
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.alignment = .Center
        
        let attributedText = NSMutableAttributedString(string: text, attributes: [NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: descriptionLabel.font])
        descriptionLabel.attributedText = attributedText
    }
    
    func populateViews() {
        guard let pageType = pageType else { return }
        
        switch pageType {
        case .PurchaseComplete:
            if let plan = plan {
                imageView.image = UIImage(named: "\(plan.activeImageName)-large")
            }
            headingLabel.text = NSLocalizedString("It’s all yours! Way to go!", comment: "Heading displayed after successful purchase of a plan")
            setDescriptionText(NSLocalizedString("Your site is doing somersaults in excitement! Now explore your site’s new features and choose where you’d like to begin.", comment: "Subtitle displayed after successful purchase of a plan"))
            imageView.widthAnchor.constraintEqualToConstant(purchaseCompleteImageViewSize).active = true
            imageView.heightAnchor.constraintEqualToConstant(purchaseCompleteImageViewSize).active = true
            actionButton.hidden = true
        case .Customize:
            imageView.image = UIImage(named: "plans-post-purchase-customize")
            headingLabel.text = NSLocalizedString("Customize Fonts & Colors", comment: "Heading for customization feature, displayed after plan purchase")
            setDescriptionText(NSLocalizedString("You now have access to custom fonts, custom colors, and custom CSS editing capabilities.", comment: "Descriptive text for customization feature, displayed after plan purchase"))
            actionButton.setTitle(NSLocalizedString("Customize My Site", comment: "Title of button displayed after plan purchase, prompting user to start customizing their site"), forState: .Normal)
        case .VideoPress:
            imageView.image = UIImage(named: "plans-post-purchase-video")
            headingLabel.text = NSLocalizedString("Bring posts to life with video", comment: "Heading for video upload feature, displayed after plan purchase")
            setDescriptionText(NSLocalizedString("You can upload and host videos on your site with VideoPress and your expanded media storage.", comment: "Descriptive text for video upload feature, displayed after plan purchase"))
            actionButton.setTitle(NSLocalizedString("Start New Post", comment: "Title of button displayed after plan purchase, prompting user to start a new post"), forState: .Normal)
        case .Themes:
            imageView.image = UIImage(named: "plans-post-purchase-themes")
            headingLabel.text = NSLocalizedString("Find a perfect, Premium theme", comment: "Title promoting premium themes, displayed after business plan purchase")
            setDescriptionText(NSLocalizedString("You now have unlimited access to Premium themes. Preview any theme on your site to get started.", comment: "Descriptive text promoting premium themes, displayed after business plan purchase"))
            actionButton.setTitle(NSLocalizedString("Browse Themes", comment: "Title of button displayed after business plan purchase"), forState: .Normal)
        }
    }
    
    @IBAction private func actionButtonTapped() {
        guard let pageType = pageType else { return }
        
        // TODO (@frosty, 2016-02-19) These navigation implementations are currently using the primary blog as
        // a temporary placeholder. Once we integrate payments through StoreKit, we should keep a record of the blog
        // that is linked to the current in-flight purchase. That blog can then be handed to this VC when it's presented.
        switch pageType {
        case .Customize:
            let service = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            WPTabBarController.sharedInstance().switchMySitesTabToCustomizeViewForBlog(service.primaryBlog())
            
            WPTabBarController.sharedInstance().dismissViewControllerAnimated(true, completion: nil)
        case .VideoPress:
            WPTabBarController.sharedInstance().dismissViewControllerAnimated(true) {
                WPTabBarController.sharedInstance().showPostTab()
            }
        case .Themes:
            let service = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            WPTabBarController.sharedInstance().switchMySitesTabToThemesViewForBlog(service.primaryBlog())
            
            WPTabBarController.sharedInstance().dismissViewControllerAnimated(true, completion: nil)
        default: break
        }
    }
}

enum PlanPostPurchasePageType: Int {
    case PurchaseComplete
    case Customize
    case VideoPress
    case Themes
    
    static func pageTypesForPlan(plan: Plan) -> [PlanPostPurchasePageType] {
        switch plan.slug {
        case "premium": return [.PurchaseComplete, .Customize, .VideoPress]
        case "business": return [.PurchaseComplete, .Customize, .VideoPress, .Themes]
        default: return []
        }
    }
}
