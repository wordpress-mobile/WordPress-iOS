import UIKit
import WordPressShared

class PlanDetailViewController: UIViewController {
    var plan: Plan!
    var siteID: Int!
    
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

    class func controllerWithPlan(plan: Plan, siteID: Int, isActive: Bool) -> PlanDetailViewController {
        let storyboard = UIStoryboard(name: "Plans", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier(NSStringFromClass(self)) as! PlanDetailViewController
        
        controller.plan = plan
        controller.siteID = siteID
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
        guard let identifier = plan.productIdentifier else {
            return
        }
        purchaseButton.selected = true
        let store = StoreKitStore()
        store.getProductsWithIdentifiers(
            Set([identifier]),
            success: { products in
                StoreKitCoordinator.instance.purchasePlan(self.plan, product: products[0], forSite: self.siteID)
            },
            failure: { error in
                DDLogSwift.logError("Error fetching Store products: \(error)")
                self.purchaseButton.selected = false
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
                    let rows: [ImmuTableRow] = group.slugs.map { slug in
                        let feature = PlanService<StoreKitStore>.featureForPlan(plan, withSlug: slug)
                        return TextRow(title: feature!.title, value: feature!.description)
                    }
                    
                    return ImmuTableSection(headerText: group.title, rows: rows, footerText: nil)
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
