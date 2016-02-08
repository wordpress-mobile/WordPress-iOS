import UIKit
import WordPressShared

class PlanDetailViewController: UITableViewController {
    var plan: Plan!
    
    private let cellIdentifier = "PlanFeatureListItem"
    
    private let tableViewHorizontalMargin: CGFloat = 24.0
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
        ImmuTable.registerRows([ FeatureListItemRow.self ], tableView: tableView)
        
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
        
        tableView.layoutMargins = UIEdgeInsetsMake(0, tableViewHorizontalMargin, 0, tableViewHorizontalMargin)
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
    static let cell = ImmuTableCell.Class(WPTableViewCellValue1)
    
    let action: ImmuTableAction? = nil
    
    let feature: PlanFeature
    let available: Bool
    
    let checkmarkLeftPadding: CGFloat = 16.0
    let webOnlyFontSize: CGFloat = 13.0
    
    init(feature: PlanFeature, available: Bool) {
        self.feature = feature
        self.available = available
    }
    
    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.font = WPStyleGuide.tableviewTextFont()
        
        cell.textLabel?.textColor = available ? WPStyleGuide.darkGrey() : WPStyleGuide.grey()
        cell.textLabel?.alpha = available ? 1.0 : 0.5
        cell.detailTextLabel?.textColor = WPStyleGuide.grey()
        
        cell.textLabel?.text = feature.title
        
        if available {
            if feature.webOnly {
                cell.detailTextLabel?.text = NSLocalizedString("WEB ONLY", comment: "Describes a feature of a WordPress.com plan that is only available to users via the web.")
                cell.detailTextLabel?.font = WPFontManager.openSansRegularFontOfSize(webOnlyFontSize)
            } else {
                cell.detailTextLabel?.text = feature.description                
                cell.detailTextLabel?.font = WPStyleGuide.tableviewTextFont()
            }
            
            let noDetailText = (feature.description ?? "").isEmpty
            if noDetailText {
                cell.accessoryView = availableCheckmark
            }
        } else {
            cell.accessoryView = unavailableMarker
        }
    }
    
    private var availableCheckmark: UIView {
        let checkmark = UIImageView(image: UIImage(named: "gridicons-checkmark-circle"))
        
        // Wrap the checkmark in a view to add some padding between it and the detailTextLabel
        let wrapper = UIView()
        wrapper.addSubview(checkmark)
        
        // Can't use autolayout here, otherwise the tableview screws things up on rotation
        wrapper.frame = CGRect(x: 0, y: 0, width: checkmarkLeftPadding + checkmark.frame.width, height: checkmark.frame.height)
        checkmark.frame.origin.x = checkmarkLeftPadding
        
        return wrapper
    }
    
    private var unavailableMarker: UIView {
        let marker = UIView(frame: CGRect(x: 0, y: 0, width: 16.0, height: 2.0))
        marker.backgroundColor = WPStyleGuide.grey()
        marker.alpha = 0.5

        return marker
    }
}
