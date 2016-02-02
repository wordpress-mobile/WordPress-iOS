import UIKit
import WordPressShared

class PlanDetailViewController: UITableViewController {
    var plan: Plan
    
    private let cellIdentifier = "PlanFeatureListItem"
    
    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()
    
    lazy private var cancelXButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "gridicons-cross"), style: .Plain, target: self, action: "closeTapped")
        button.accessibilityLabel = NSLocalizedString("Close", comment: "Dismiss the current view")
        
        return button
    }()
    
    init(plan: Plan) {
        self.plan = plan
        super.init(style: .Plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        ImmuTable.registerRows([FeatureListItemRow.self], tableView: tableView)
        
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
    static let cell = ImmuTableCell.Class(WPTableViewCellValue1)
    
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
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = (webOnly) ? "WEB ONLY" : detailText
        cell.accessoryType = (shouldShowCheckmark) ? .Checkmark : .None
        
        WPStyleGuide.configureTableViewCell(cell)
    }
}
