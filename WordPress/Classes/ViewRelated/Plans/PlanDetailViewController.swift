import UIKit
import WordPressShared

class PlanDetailViewController: UIViewController {
    var plan: Plan!
    
    private let cellIdentifier = "PlanFeatureListItem"
    
    private let tableViewHorizontalMargin: CGFloat = 24.0
    private let planImageDropshadowRadius: CGFloat = 3.0
    
    var isActivePlan = false
    
    private var tableViewModel = ImmuTable.Empty {
        didSet {
            tableView?.reloadData()
        }
    }
    var viewModel: PlanFeatureViewModel = .Loading {
        didSet {
            bindViewModel(viewModel)
            updateNoResults()
        }
    }
    
    private let noResultsView = WPNoResultsView()
    
    func updateNoResults() {
        if let noResultsViewModel = viewModel.noResultsViewModel {
            showNoResults(noResultsViewModel)
        } else {
            hideNoResults()
        }
    }
    func showNoResults(viewModel: WPNoResultsView.Model) {
        noResultsView.bindViewModel(viewModel)
        if noResultsView.isDescendantOfView(tableView) {
            noResultsView.centerInSuperview()
        } else {
            tableView.addSubviewWithFadeAnimation(noResultsView)
        }
    }
    
    func hideNoResults() {
        noResultsView.removeFromSuperview()
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var planImageView: UIImageView!
    @IBOutlet weak var dropshadowImageView: UIImageView!
    @IBOutlet weak var planTitleLabel: UILabel!
    @IBOutlet weak var planDescriptionLabel: UILabel!
    @IBOutlet weak var planPriceLabel: UILabel!
    @IBOutlet weak var purchaseButton: UIButton!

    private lazy var currentPlanLabel: UIView = {
        let label = UILabel()
        label.font = WPFontManager.systemSemiBoldFontOfSize(13.0)
        label.textColor = WPStyleGuide.validGreen()
        label.text = NSLocalizedString("Current Plan", comment: "").uppercaseStringWithLocale(NSLocale.currentLocale())
        label.translatesAutoresizingMaskIntoConstraints = false

        // Wrapper view required for spacing to work out correctly, as the header stackview
        // is baseline-based, and so acts differently for a label vs view.
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(label)
        wrapper.pinSubviewToAllEdges(label)
        
        return wrapper
    }()
    
    @IBOutlet weak var headerInfoStackView: UIStackView!

    class func controllerWithPlan(plan: Plan, isActive: Bool) -> PlanDetailViewController {
        let storyboard = UIStoryboard(name: "Plans", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier(NSStringFromClass(self)) as! PlanDetailViewController
        
        controller.plan = plan
        controller.isActivePlan = isActive
        
        return controller
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAppearance()
        configureTableView()
        updateNoResults()
    }
    
    private func configureAppearance() {
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
        
        planTitleLabel.textColor = WPStyleGuide.darkGrey()
        planDescriptionLabel.textColor = WPStyleGuide.grey()
        planPriceLabel.textColor = WPStyleGuide.grey()
        
        purchaseButton.tintColor = WPStyleGuide.wordPressBlue()
        
        dropshadowImageView.backgroundColor = UIColor.whiteColor()
        configurePlanImageDropshadow()
    }
    
    private func configureTableView() {
        ImmuTable.registerRows([ FeatureListItemRow.self ], tableView: tableView)
    
        tableView.layoutMargins = UIEdgeInsetsMake(0, tableViewHorizontalMargin, 0, tableViewHorizontalMargin)
    }
    
    private func configurePlanImageDropshadow() {
        dropshadowImageView.layer.masksToBounds = false
        dropshadowImageView.layer.shadowColor = WPStyleGuide.greyLighten30().CGColor
        dropshadowImageView.layer.shadowOpacity = 1.0
        dropshadowImageView.layer.shadowRadius = planImageDropshadowRadius
        dropshadowImageView.layer.shadowOffset = .zero
        dropshadowImageView.layer.shadowPath = UIBezierPath(ovalInRect: dropshadowImageView.bounds).CGPath
    }
    
    lazy var paddingView = UIView()
    
    private func populateHeader(plan: Plan, isActivePlan: Bool) {
        planImageView.image = plan.image
        planTitleLabel.text = plan.fullTitle
        planDescriptionLabel.text = plan.description
        planPriceLabel.text = priceDescriptionForPlan(plan)
        
        if isActivePlan {
            purchaseButton.removeFromSuperview()
            headerInfoStackView.addArrangedSubview(currentPlanLabel)
        } else if plan.isFreePlan {
            purchaseButton.removeFromSuperview()
            headerInfoStackView.addArrangedSubview(paddingView)
        }
    }
    
    func bindViewModel(viewModel: PlanFeatureViewModel) {
        self.tableViewModel = viewModel.tableViewModel
        title = plan.title
        populateHeader(plan, isActivePlan: isActivePlan)
    }
    
    // TODO: Prices should always come from StoreKit
    // @frosty 2016-02-04
    private func priceDescriptionForPlan(plan: Plan) -> String? {
        switch plan.slug {
        case "free":
            return "Free for life"
        case "premium":
            return "$99.99 per year"
        case "business":
            return "$299.99 per year"
        default:
            return nil
        }
    }
    
    //MARK: - IBActions
    
    @IBAction private func purchaseTapped() {
        purchaseButton.selected = true
        
        // TODO (@frosty 2016-02-26): This is a temporary fake StoreKit
        // transaction process to simulate navigation to the post purchase screens.
        // This should be removed when we integrate StoreKit.
        func showSuccessAlert() {
            guard let plan = plan else { return }
            
            let alert = UIAlertController(title: "Thank You", message: "Your purchase was successful.", preferredStyle: .Alert)
            alert.addActionWithTitle("OK", style: .Default, handler: { action in })
            
            let postPurchase = PlanPostPurchaseViewController(plan: plan)
            let navigationController = RotationAwareNavigationViewController(rootViewController: postPurchase)
            navigationController.modalTransitionStyle = .CrossDissolve
            navigationController.modalPresentationStyle = .FormSheet
            navigationController.navigationBar.shadowImage = UIImage(color: UIColor.clearColor(), havingSize: CGSize(width: 1, height: 1))
            presentViewController(navigationController, animated: true, completion: nil)

            navigationController.presentViewController(alert, animated: true, completion: nil)
            
            purchaseButton.selected = false
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), {
            let alert = UIAlertController(title: "Confirm Your In-App Purchase", message: "Do you want to buy one WordPress.com Premium for 1 year for $99.99?", preferredStyle: .Alert)
            alert.addActionWithTitle("Cancel", style: .Cancel, handler: { action in
                self.purchaseButton.selected = false
            })
            alert.addActionWithTitle("Buy", style: .Default, handler: { action in
                showSuccessAlert()
            })
            
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }
    
    enum PlanFeatureViewModel {
        case Loading
        case Ready(Plan)
        case Error(String)
        
        var tableViewModel: ImmuTable {
            switch self {
            case .Loading, .Error(_):
                return ImmuTable.Empty
            case .Ready(let plan):
                guard let groups = PlanFeatureGroup.groupsForPlan(plan) else {
                    return ImmuTable.Empty
                }
                
                return ImmuTable(sections: groups.map { group in
                    let features = group.slugs.map { PlanService.featureForPlan(plan, withSlug: $0) }
                    
                    return ImmuTableSection(headerText: group.title, rows: features.map({ TextRow(title: $0!.title, value: $0!.description) }), footerText: nil)
                })
            }
        }
        
        var noResultsViewModel: WPNoResultsView.Model? {
            switch self {
            case .Loading:
                return WPNoResultsView.Model(
                    title: NSLocalizedString("Loading Plan...", comment: "Text displayed while loading plans details")
                )
            case .Ready(_):
                return nil
            case .Error(_):
                return WPNoResultsView.Model(
                    title: NSLocalizedString("Oops", comment: ""),
                    message: NSLocalizedString("There was an error loading the plan", comment: ""),
                    buttonTitle: NSLocalizedString("Contact support", comment: "")
                )
            }
        }
    }
}

// MARK: Table View Data Source / Delegate
extension PlanDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tableViewModel.sections.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewModel.sections[section].rows.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = tableViewModel.rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(row.reusableIdentifier, forIndexPath: indexPath)
        
        row.configureCell(cell)
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // Rows have alternate colors
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = WPStyleGuide.greyLighten30()
        } else {
            cell.backgroundColor = WPStyleGuide.lightGrey()
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableViewModel.sections[section].headerText
    }
}

struct FeatureListItemRow : ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellValue1)
    
    let action: ImmuTableAction? = nil
    
    let title: String
    let webOnly: Bool
    
    let checkmarkLeftPadding: CGFloat = 16.0
    let webOnlyFontSize: CGFloat = 13.0
    
    init(feature: PlanFeature) {
        self.title = feature.title
        
        // TODO: (@frosty, 2016-03-14) Currently hardcoded because the API doesn't provide
        // us with this info. Remove once we switch to a different design that doesn't display 'web only'.
        self.webOnly = (feature.slug == "custom-domain")
    }
    
    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = text
        cell.textLabel?.font = WPStyleGuide.tableviewTextFont()
        cell.textLabel?.textColor = textColor

        cell.detailTextLabel?.text = detailText
        cell.detailTextLabel?.font = detailTextFont
        cell.detailTextLabel?.textColor = WPStyleGuide.grey()

        cell.accessibilityLabel = accessibilityLabel
    }

    var text: String? {
        return title
    }

    var textColor = WPStyleGuide.darkGrey()

    var detailText: String? {
        if webOnly {
            return NSLocalizedString("WEB ONLY", comment: "Describes a feature of a WordPress.com plan that is only available to users via the web.")
        } else {
            return nil
        }
    }

    var detailTextFont: UIFont {
        if webOnly {
            return WPFontManager.systemRegularFontOfSize(webOnlyFontSize)
        } else {
            return WPStyleGuide.tableviewTextFont()
        }
    }

    var accessibilityLabel: String? {
        guard let availableAccessibilityLabel = self.availableAccessibilityLabel else {
            return nil
        }
        return String(format: "%@. %@", title, availableAccessibilityLabel)
    }

    var availableAccessibilityLabel: String? {
        if webOnly {
            return NSLocalizedString("Included in web version", comment: "Spoken text. A feature is included in the plan")
        } else {
            return NSLocalizedString("Included", comment: "Spoken text. A feature is included in the plan")
        }
    }
}
