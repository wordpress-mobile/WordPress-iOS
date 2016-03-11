import UIKit
import WordPressShared

class PlanDetailViewController: UIViewController {
    var plan: Plan!
    
    private let cellIdentifier = "PlanFeatureListItem"
    
    private let tableViewHorizontalMargin: CGFloat = 24.0
    private let planImageDropshadowRadius: CGFloat = 3.0
    
    var isActivePlan = false
    
    private var viewModel: ImmuTable! = nil
    
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
        
        configureAppearance()
        configureImmuTable()
        populateHeader()
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
                    if let description = planFeature.description {
                        return TextRow(title: planFeature.title, value: description)
                    } else {
                        return FeatureListItemRow(feature: planFeature, available: available)
                    }
                }
                
                return FeatureListItemRow(feature: feature, available: available)
            } ) ]
        )
        
        tableView.layoutMargins = UIEdgeInsetsMake(0, tableViewHorizontalMargin, 0, tableViewHorizontalMargin)
    }
    
    lazy var paddingView = UIView()
    
    private func populateHeader() {
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
            let alert = UIAlertController(title: "Thank You", message: "Your purchase was successful.", preferredStyle: .Alert)
            alert.addActionWithTitle("OK", style: .Default, handler: { action in })
            
            let postPurchase = PlanPostPurchaseViewController(plan: self.plan)
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
}

// MARK: Table View Data Source / Delegate
extension PlanDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = viewModel.rowAtIndexPath(indexPath)
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
}

struct FeatureListItemRow : ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellValue1)
    
    let action: ImmuTableAction? = nil
    
    let title: String
    let webOnly: Bool
    let available: Bool
    
    let checkmarkLeftPadding: CGFloat = 16.0
    let webOnlyFontSize: CGFloat = 13.0
    
    init(feature: PlanFeature, available: Bool) {
        precondition(feature.description == nil, "Features with a description should use TextRow instead")

        self.title = feature.title
        self.webOnly = feature.webOnly
        self.available = available
    }
    
    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = text
        cell.textLabel?.font = WPStyleGuide.tableviewTextFont()
        cell.textLabel?.textColor = textColor

        cell.detailTextLabel?.text = detailText
        cell.detailTextLabel?.font = detailTextFont
        cell.detailTextLabel?.textColor = WPStyleGuide.grey()

        cell.accessoryView = accessoryView
        cell.accessibilityLabel = accessibilityLabel
    }

    var text: String? {
        return title
    }

    var textColor: UIColor {
        if available {
            return WPStyleGuide.darkGrey()
        } else {
            return WPStyleGuide.grey().colorWithAlphaComponent(0.5)
        }
    }

    var detailText: String? {
        if available && webOnly {
            return NSLocalizedString("WEB ONLY", comment: "Describes a feature of a WordPress.com plan that is only available to users via the web.")
        } else {
            return nil
        }
    }

    var detailTextFont: UIFont {
        if available && webOnly {
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
        switch (availableIndicator, webOnly) {
        case (.Some(false), _):
            return NSLocalizedString("Not included", comment: "Spoken text. A feature is not included in the plan")
        case (.Some(true), true):
            return NSLocalizedString("Included in web version", comment: "Spoken text. A feature is included in the plan")
        case (.Some(true), false):
            return NSLocalizedString("Included", comment: "Spoken text. A feature is included in the plan")
        case (.None, _):
            return nil
        }
    }

    var availableIndicator: Bool? {
        return available
    }

    var accessoryView: UIView? {
        return availableIndicator.map({ available in
            if available {
                return availableMarker
            } else {
                return unavailableMarker
            }
        })
    }
    
    private var availableMarker: UIView {
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
