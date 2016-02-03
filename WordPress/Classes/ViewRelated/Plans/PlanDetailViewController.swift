import UIKit
import WordPressShared

class PlanDetailViewController: UITableViewController {
    var plan: Plan!
    
    private let cellIdentifier = "PlanFeatureListItem"
    
    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()
    
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
        
        setupImmuTable()
    }
    
    private func setupImmuTable() {
        handler.viewModel = ImmuTable(sections:
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
