import UIKit
import Gridicons
import WordPressShared
import WordPressKit

class PlanPostPurchaseViewController: UIViewController {

    fileprivate let pageControlHeight: CGFloat = 59
    fileprivate let contentTopInset: CGFloat = 25
    fileprivate var headingParallaxMaxTranslation: CGFloat = 200
    fileprivate var descriptionParallaxMaxTranslation: CGFloat = 100

    fileprivate weak var pageControl: UIPageControl!
    fileprivate weak var scrollView: UIScrollView!

    var pageTypes: [PlanPostPurchasePageType]!
    @objc var pages = [PlanPostPurchasePageViewController]()
    var plan: Plan

    lazy fileprivate var cancelXButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: Gridicon.iconOfType(.cross), style: .plain, target: self, action: #selector(PlanPostPurchaseViewController.closeTapped))
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

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // If the view is changing size (e.g. on rotation, or multitasking), scroll to the correct page boundary based on the new size
        coordinator.animate(alongsideTransition: { context in
            self.scrollView.setContentOffset(CGPoint(x: CGFloat(self.currentScrollViewPage()) * size.width, y: 0), animated: true)
            }, completion: nil)
    }

    fileprivate func addPageControl() {
        let pageControl = UIPageControl()
        view.addSubview(pageControl)

        pageControl.tintColor = UIColor.white

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pageControl.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        pageControl.heightAnchor.constraint(equalToConstant: pageControlHeight).isActive = true

        pageControl.addTarget(self, action: #selector(PlanPostPurchaseViewController.pageControlChanged), for: .valueChanged)
        self.pageControl = pageControl
    }

    fileprivate func addScrollView() {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.backgroundColor = WPStyleGuide.wordPressBlue()

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: pageControl.topAnchor).isActive = true

        let container = UIStackView()
        container.axis = .horizontal
        scrollView.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        scrollView.pinSubviewToAllEdges(container)

        for pageType in pageTypes {
            addNewPageViewControllerForPageType(pageType, toContainer: container)
        }

        pageControl.numberOfPages = pages.count

        container.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: CGFloat(pages.count))

        self.scrollView = scrollView
    }

    fileprivate func addNewPageViewControllerForPageType(_ pageType: PlanPostPurchasePageType, toContainer container: UIStackView) {
        let page = PlanPostPurchasePageViewController.controller()
        addChildViewController(page)

        page.view.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(page.view)

        page.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        page.view.bottomAnchor.constraint(equalTo: pageControl.topAnchor).isActive = true

        page.didMove(toParentViewController: self)

        page.plan = plan
        page.pageType = pageType
        page.view.accessibilityElementsHidden = (pageType != .PurchaseComplete)
        page.view.shouldGroupAccessibilityChildren = true

        pages.append(page)
    }

    @IBAction func pageControlChanged() {
        let currentIndex = currentScrollViewPage()

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

    @objc func closeTapped() {
        dismiss(animated: true, completion: nil)
    }
}

extension PlanPostPurchaseViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.bounds.width

        guard pageWidth > 0 else { return }

        let centerX = scrollView.contentOffset.x + (pageWidth / 2)
        let currentPageFraction = (centerX / pageWidth)
        let currentPageIndex = Int(floor(currentPageFraction))

        for (index, page) in pages.enumerated() {
            let pageCenter = CGFloat(index) + 0.5
            let offset = currentPageFraction - pageCenter

            page.headingLabel.transform = CGAffineTransform(translationX: offset * -headingParallaxMaxTranslation, y: 0)
            page.descriptionLabel.transform = CGAffineTransform(translationX: offset * -descriptionParallaxMaxTranslation, y: 0)
        }

        if scrollView.isDragging {
            pageControl.currentPage = currentPageIndex
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollView.isUserInteractionEnabled = true
    }

    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        var targetPage = currentScrollViewPage()

        switch direction {
        case .right: targetPage -= 1
        case .left: targetPage += 1
        default: break
        }

        let success = scrollToPage(targetPage, animated: false)
        if success {
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
        }

        return success
    }

    fileprivate func currentScrollViewPage() -> Int {
        // Calculate which plan's VC is at the center of the view
        let pageWidth = scrollView.bounds.width
        let centerX = scrollView.contentOffset.x + (pageWidth / 2)
        let currentPage = Int(floor(centerX / pageWidth))

        // Keep it within bounds
        return currentPage.clamp(min: 0, max: pages.count - 1)
    }

    /// - Returns: True if there was valid page to scroll to, false if we've reached the beginning / end
    @discardableResult fileprivate func scrollToPage(_ page: Int, animated: Bool) -> Bool {
        guard pages.indices.contains(page) else { return false }

        let pageWidth = view.bounds.width
        scrollView.setContentOffset(CGPoint(x: CGFloat(page) * pageWidth, y: 0), animated: animated)

        for (index, pageVC) in pages.enumerated() {
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

    @objc let purchaseCompleteImageViewSize: CGFloat = 90

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

    @objc class func controller() -> PlanPostPurchasePageViewController {
        let storyboard = UIStoryboard(name: "Plans", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: NSStringFromClass(self)) as! PlanPostPurchasePageViewController

        return controller
    }

    @objc func setDescriptionText(_ text: String) {
        let lineHeight: CGFloat = 21

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.alignment = .center

        let attributedText = NSMutableAttributedString(string: text, attributes: [.paragraphStyle: paragraphStyle, .font: descriptionLabel.font])
        descriptionLabel.attributedText = attributedText
    }

    @objc func populateViews() {
        guard let pageType = pageType else { return }

        switch pageType {
        case .PurchaseComplete:
            if let plan = plan {
                imageView.setImageWith(plan.activeIconUrl)
            }
            headingLabel.text = NSLocalizedString("It’s all yours! Way to go!", comment: "Heading displayed after successful purchase of a plan")
            setDescriptionText(NSLocalizedString("Your site is doing somersaults in excitement! Now explore your site’s new features and choose where you’d like to begin.", comment: "Subtitle displayed after successful purchase of a plan"))
            imageView.widthAnchor.constraint(equalToConstant: purchaseCompleteImageViewSize).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: purchaseCompleteImageViewSize).isActive = true
            actionButton.isHidden = true
        case .Customize:
            imageView.image = UIImage(named: "plans-post-purchase-customize")
            headingLabel.text = NSLocalizedString("Customize Fonts & Colors", comment: "Heading for customization feature, displayed after plan purchase")
            setDescriptionText(NSLocalizedString("You now have access to custom fonts, custom colors, and custom CSS editing capabilities.", comment: "Descriptive text for customization feature, displayed after plan purchase"))
            actionButton.setTitle(NSLocalizedString("Customize My Site", comment: "Title of button displayed after plan purchase, prompting user to start customizing their site"), for: UIControlState())
        case .VideoPress:
            imageView.image = UIImage(named: "plans-post-purchase-video")
            headingLabel.text = NSLocalizedString("Bring posts to life with video", comment: "Heading for video upload feature, displayed after plan purchase")
            setDescriptionText(NSLocalizedString("You can upload and host videos on your site with VideoPress and your expanded media storage.", comment: "Descriptive text for video upload feature, displayed after plan purchase"))
            actionButton.setTitle(NSLocalizedString("Start New Post", comment: "Title of button displayed after plan purchase, prompting user to start a new post"), for: UIControlState())
        case .Themes:
            imageView.image = UIImage(named: "plans-post-purchase-themes")
            headingLabel.text = NSLocalizedString("Find a perfect, Premium theme", comment: "Title promoting premium themes, displayed after business plan purchase")
            setDescriptionText(NSLocalizedString("You now have unlimited access to Premium themes. Preview any theme on your site to get started.", comment: "Descriptive text promoting premium themes, displayed after business plan purchase"))
            actionButton.setTitle(NSLocalizedString("Browse Themes", comment: "Title of button displayed after business plan purchase"), for: UIControlState())
        }
    }

    @IBAction fileprivate func actionButtonTapped() {
        guard let pageType = pageType else { return }

        // TODO (@frosty, 2016-02-19) These navigation implementations are currently using the primary blog as
        // a temporary placeholder. Once we integrate payments through StoreKit, we should keep a record of the blog
        // that is linked to the current in-flight purchase. That blog can then be handed to this VC when it's presented.
        switch pageType {
        case .Customize:
            let service = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            WPTabBarController.sharedInstance().switchMySitesTabToCustomizeView(for: service.primaryBlog())

            WPTabBarController.sharedInstance().dismiss(animated: true, completion: nil)
        case .VideoPress:
            WPTabBarController.sharedInstance().dismiss(animated: true) {
                WPTabBarController.sharedInstance().showPostTab()
            }
        case .Themes:
            let service = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            WPTabBarController.sharedInstance().switchMySitesTabToThemesView(for: service.primaryBlog())

            WPTabBarController.sharedInstance().dismiss(animated: true, completion: nil)
        default: break
        }
    }
}

enum PlanPostPurchasePageType: String {
    case PurchaseComplete = "purchase-complete"
    case Customize = "custom-design"
    case VideoPress = "videopress"
    case Themes = "premium-themes"

    // This is the order we'd like pages to appear in the post purchase flow
    static let orderedPageTypes: [PlanPostPurchasePageType] = [ .Customize, .VideoPress, .Themes ]

    static func pageTypesForPlan(_ plan: Plan) -> [PlanPostPurchasePageType] {
        // Get all of the page types for the plan's features
        let slugs = plan.featureGroups
            .flatMap({ $0.slugs })
            .flatMap(PlanPostPurchasePageType.init)

        // Put them in the order we'd like
        return [.PurchaseComplete] + orderedPageTypes.filter({ slugs.contains($0) })
    }
}
