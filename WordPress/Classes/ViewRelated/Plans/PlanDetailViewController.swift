import UIKit
import WordPressShared

class PlanDetailViewController: UITableViewController {
    var plan: Plan!
    
    private let cellIdentifier = "PlanFeatureListItem"
    
    private var viewModel: ImmuTable! = nil
    
    @IBOutlet weak var planImageView: UIImageView!
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
    }
    
    private func configureImmuTable() {
        viewModel = ImmuTable(sections:
            [ ImmuTableSection(rows: [
                FeatureListItemRow(title: "WordPress.com Site"),
                FeatureListItemRow(title: "Full Access to Web Version"),
                FeatureListItemRow(title: "A Custom Site Address", webOnly: true),
                FeatureListItemRow(title: "No Ads"),
                FeatureListItemRow(title: "Custom Fonts & Colors"),
                FeatureListItemRow(title: "CSS Editing"),
                FeatureListItemRow(title: "Video Storage & Hosting"),
                FeatureListItemRow(title: "eCommerce", available: false),
                FeatureListItemRow(title: "Premium Themes", available: false),
                FeatureListItemRow(title: "Google Analytics", available: false),
                FeatureListItemRow(title: "Storage Space", detailText: "13GB"),
                FeatureListItemRow(title: "Support", detailText: "In-App & Direct Email"),
                ])
            ]
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
            return "Free!"
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
    
    @IBAction func purchaseTapped() {
    }
}

// MARK: Table View Data Source
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
    
    let title: String
    let webOnly: Bool
    let available: Bool
    let detailText: String?
    let action: ImmuTableAction? = nil
    
    init(title: String, webOnly: Bool = false, available: Bool = true, detailText: String? = nil) {
        self.title = title
        self.webOnly = webOnly
        self.available = available
        self.detailText = detailText
    }
    
    func configureCell(cell: UITableViewCell) {
        let cell = cell as! PlanFeatureListCell
        cell.titleLabel.text = title
        cell.detailLabel.text = detailText
        
        cell.titleLabel.textColor = available ? WPStyleGuide.darkGrey() : WPStyleGuide.grey()
        cell.titleLabel.alpha = available ? 1.0 : 0.5
        
        cell.webOnlyLabel.hidden = !webOnly
        cell.unavailableFeatureMarker.hidden = available
        
        let noDetailText = (detailText ?? "").isEmpty
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

@IBDesignable
class BorderedButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 3.0 {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 1.0 {
        didSet {
            updateAppearance()
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        updateAppearance()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setTitleColor(UIColor.whiteColor(), forState: [.Highlighted])
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)

        updateAppearance()
    }
    
    private func updateAppearance() {
        contentEdgeInsets = UIEdgeInsets(top: 10.0, left: 19.0, bottom: 10.0, right: 19.0)
        
        layer.masksToBounds = true
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = tintColor.CGColor
        layer.borderColor = tintColor.CGColor
        
        setTitleColor(tintColor, forState: .Normal)
        
        setBackgroundImage(UIImage(color: tintColor), forState: .Highlighted)
    }
}

