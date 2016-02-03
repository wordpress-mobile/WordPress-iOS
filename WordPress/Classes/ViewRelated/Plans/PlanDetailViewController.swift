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
        let controller = storyboard.instantiateViewControllerWithIdentifier("PlanDetailViewController") as! PlanDetailViewController
        
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
                FeatureListItemRow(title: "eCommerce", disabled: true),
                FeatureListItemRow(title: "Premium Themes", disabled: true),
                FeatureListItemRow(title: "Google Analytics", disabled: true),
                FeatureListItemRow(title: "Storage Space", detailText: "13GB"),
                FeatureListItemRow(title: "Support", detailText: "In-App & Direct Email"),
                ])
            ]
        )
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
    let disabled: Bool
    let detailText: String?
    let action: ImmuTableAction? = nil
    
    private var shouldShowCheckmark: Bool {
        return !disabled && detailText == nil
    }
    
    init(title: String, webOnly: Bool = false, disabled: Bool = false, detailText: String? = nil) {
        self.title = title
        self.webOnly = webOnly
        self.disabled = disabled
        self.detailText = detailText
    }
    
    func configureCell(cell: UITableViewCell) {
        let cell = cell as! PlanFeatureListCell
        cell.titleLabel.text = title
        cell.detailLabel.text = detailText
        cell.webOnlyLabel.hidden = !webOnly
        cell.checkmark.hidden = !shouldShowCheckmark
        
        cell.titleLabel.textColor = disabled ? WPStyleGuide.grey() : WPStyleGuide.darkGrey()
        
        if disabled {
            cell.titleLabel.alpha = 0.5
            cell.disabledMarker.hidden = false
        } else {
            cell.titleLabel.alpha = 1.0
            cell.disabledMarker.hidden = true
        }
    }
}

class PlanFeatureListCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var webOnlyLabel: UILabel!
    @IBOutlet weak var checkmark: UIImageView!
    @IBOutlet weak var disabledMarker: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        disabledMarker.backgroundColor = WPStyleGuide.grey()
        webOnlyLabel.textColor = WPStyleGuide.grey()
        detailLabel.textColor = WPStyleGuide.grey()
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

