import UIKit
import WordPressShared

class PlanDetailViewController: UITableViewController {
    var plan: Plan!
    
    private let cellIdentifier = "PlanFeatureListItem"
    
    private let planImageDropshadowRadius: CGFloat = 3.0
    
    private var viewModel: ImmuTable! = nil
    
    @IBOutlet weak var planImageView: UIImageView!
    @IBOutlet weak var dropshadowImageView: UIImageView!
    @IBOutlet weak var planTitleLabel: UILabel!
    @IBOutlet weak var planDescriptionLabel: UILabel!
    @IBOutlet weak var planPriceLabel: UILabel!
    @IBOutlet weak var purchaseButton: UIButton!
    
    lazy private var cancelXButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "gridicons-cross"), style: .Plain, target: self, action: "closeTapped")
        button.accessibilityLabel = NSLocalizedString("Close", comment: "Dismiss the current view")
        
        return button
    }()
    
    class func controllerWithPlan(plan: Plan) -> PlanDetailViewController {
        let storyboard = UIStoryboard(name: "Plans", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier(NSStringFromClass(self)) as! PlanDetailViewController
        
        controller.plan = plan
        
        return controller
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = plan.title
        navigationItem.leftBarButtonItem = cancelXButton
        
        configureAppearance()
        configureImmuTable()
        populateHeader()
    }
    
    private func configureAppearance() {
        planTitleLabel.textColor = WPStyleGuide.darkGrey()
        planDescriptionLabel.textColor = WPStyleGuide.grey()
        planPriceLabel.textColor = WPStyleGuide.grey()
        
        purchaseButton.tintColor = WPStyleGuide.wordPressBlue()
        
        dropshadowImageView.backgroundColor = UIColor.whiteColor()
        configurePlanImageDropshadow()
    }
    
    private func configurePlanImageDropshadow() {
        dropshadowImageView.layer.masksToBounds = false
        dropshadowImageView.layer.shadowColor = WPStyleGuide.greyLighten30().CGColor
        dropshadowImageView.layer.shadowOpacity = 1.0
        dropshadowImageView.layer.shadowRadius = planImageDropshadowRadius
        dropshadowImageView.layer.shadowOffset = .zero
        dropshadowImageView.layer.shadowPath = UIBezierPath(ovalInRect: dropshadowImageView.bounds).CGPath
    }
    
    private func configureImmuTable() {
        viewModel = ImmuTable(sections:
            [ ImmuTableSection(rows: PlanFeature.allFeatures.map { feature in
                let available = plan.features.contains(feature)
                
                if available {
                    // If a feature is 'available', we have to find and use the feature instance
                    // from the _plan's_ list of features, as it will have the correct associated values
                    // for any enum case that has associated values.
                    let index = plan.features.indexOf(feature)
                    let planFeature = plan.features[index!]
                    return FeatureListItemRow(feature: planFeature, available: available)
                }
                
                return FeatureListItemRow(feature: feature, available: available)
            } ) ]
        )
    }
    
    private func populateHeader() {
        planImageView.image = plan.image
        planTitleLabel.text = plan.fullTitle
        planDescriptionLabel.text = plan.description
        planPriceLabel.text = priceDescriptionForPlan(plan)
    }
    
    // TODO: Prices should always come from StoreKit
    // @frosty 2016-02-04
    private func priceDescriptionForPlan(plan: Plan) -> String? {
        switch plan {
        case .Free:
            return "$0 for life"
        case .Premium:
            return "$99.99 per year"
        case .Business:
            return "$299.99 per year"
        }
    }
    
    //MARK: - IBActions
    
    @IBAction private func closeTapped() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction private func purchaseTapped() {
    }
}

// MARK: Table View Data Source / Delegate
extension PlanDetailViewController {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = viewModel.rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(row.reusableIdentifier, forIndexPath: indexPath)
        
        row.configureCell(cell)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // Rows have alternate colors
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = WPStyleGuide.greyLighten30()
        } else {
            cell.backgroundColor = WPStyleGuide.lightGrey()
        }
    }
}

struct FeatureListItemRow : ImmuTableRow {
    static let cell = ImmuTableCell.Class(PlanFeatureListCell)
    
    let action: ImmuTableAction? = nil
    
    let feature: PlanFeature
    let available: Bool
    
    init(feature: PlanFeature, available: Bool) {
        self.feature = feature
        self.available = available
    }
    
    func configureCell(cell: UITableViewCell) {
        let cell = cell as! PlanFeatureListCell
        cell.titleLabel.text = feature.title
        cell.detailLabel.text = feature.description
        
        cell.titleLabel.textColor = available ? WPStyleGuide.darkGrey() : WPStyleGuide.grey()
        cell.titleLabel.alpha = available ? 1.0 : 0.5
        
        cell.webOnlyLabel.hidden = !feature.webOnly
        cell.unavailableFeatureMarker.hidden = available
        
        let noDetailText = (feature.description ?? "").isEmpty
        cell.availableFeatureStackView.hidden = !available || !noDetailText
        cell.detailLabel.hidden = noDetailText
    }
}

class PlanFeatureListCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var webOnlyLabel: UILabel!
    @IBOutlet weak var availableFeatureStackView: UIStackView!
    @IBOutlet weak var unavailableFeatureMarker: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        webOnlyLabel.text = NSLocalizedString("WEB ONLY", comment: "Describes a feature of a WordPress.com plan that is only available to users via the web.")
        
        unavailableFeatureMarker.backgroundColor = WPStyleGuide.grey()
        webOnlyLabel.textColor = WPStyleGuide.grey()
        detailLabel.textColor = WPStyleGuide.grey()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        detailLabel.text = nil
        titleLabel.text = nil
    }
}
