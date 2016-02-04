import UIKit
import WordPressShared

struct PlanListRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellSubtitle)
    static let customHeight: Float? = 92

    let title: String
    let active: Bool
    let price: String
    let description: String
    let icon: UIImage

    let action: ImmuTableAction? = nil
    
    func configureCell(cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.imageView?.image = icon
        cell.textLabel?.attributedText = attributedTitle
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.text = description
        cell.detailTextLabel?.textColor = WPStyleGuide.grey()
        cell.selectionStyle = .None
    }

    private var attributedTitle: NSAttributedString {
        return Formatter.attributedTitle(title, price: price, active: active)
    }

    struct Formatter {
        static let titleAttributes = [
            NSFontAttributeName: WPStyleGuide.tableviewTextFont(),
            NSForegroundColorAttributeName: WPStyleGuide.tableViewActionColor()
        ]
        static let priceAttributes = [
            NSFontAttributeName: WPFontManager.openSansRegularFontOfSize(14.0),
            NSForegroundColorAttributeName: WPStyleGuide.darkGrey()
        ]
        static let pricePeriodAttributes = [
            NSFontAttributeName: WPFontManager.openSansItalicFontOfSize(13.0),
            NSForegroundColorAttributeName: WPStyleGuide.greyLighten20()
        ]

        static func attributedTitle(title: String, price: String, active: Bool) -> NSAttributedString {
            let planTitle = NSAttributedString(string: title, attributes: titleAttributes)

            let attributedTitle = NSMutableAttributedString(attributedString: planTitle)

            if active {
                let currentPlanAttributes = [
                    NSFontAttributeName: WPFontManager.openSansSemiBoldFontOfSize(11.0),
                    NSForegroundColorAttributeName: WPStyleGuide.validGreen()
                ]
                let currentPlan = NSLocalizedString("Current Plan", comment: "").uppercaseStringWithLocale(NSLocale.currentLocale())
                let attributedCurrentPlan = NSAttributedString(string: currentPlan, attributes: currentPlanAttributes)
                attributedTitle.appendString(" ")
                attributedTitle.appendAttributedString(attributedCurrentPlan)
            } else if !price.isEmpty {
                attributedTitle.appendString(" ")
                let attributedPrice = NSAttributedString(string: price, attributes: priceAttributes)
                attributedTitle.appendAttributedString(attributedPrice)

                attributedTitle.appendString(" ")
                let pricePeriod = NSAttributedString(string: NSLocalizedString("per year", comment: ""), attributes: pricePeriodAttributes)
                attributedTitle.appendAttributedString(pricePeriod)
            }
            return attributedTitle
        }
    }
}

struct PlanListViewModel {
    let activePlan: Plan?

    var tableViewModel: ImmuTable {
        return ImmuTable(sections: [
            ImmuTableSection(
                headerText: NSLocalizedString("WordPress.com Plans", comment: "Title for the Plans list header"),
                rows: [
                    rowForPlan(.Free),
                    rowForPlan(.Premium),
                    rowForPlan(.Business)
                ])
            ])
    }

    private func rowForPlan(plan: Plan) -> PlanListRow {
        let active = (activePlan == plan)
        let icon = active ? plan.activeImage : plan.image

        return PlanListRow(
            title: plan.title,
            active: active,
            price: priceForPlan(plan),
            description: plan.description,
            icon: icon
        )
    }

    // TODO: Prices should always come from StoreKit
    // @koke 2016-02-02
    private func priceForPlan(plan: Plan) -> String {
        switch plan {
        case .Free:
            return ""
        case .Premium:
            return "$99.99"
        case .Business:
            return "$299.99"
        }
    }
}

final class PlanListViewController: UITableViewController {
    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()
    private let viewModel: PlanListViewModel

    static let restorationIdentifier = "PlanList"

    convenience init(blog: Blog) {
        self.init(activePlan: blog.plan)
    }

    convenience init(activePlan: Plan?) {
        let viewModel = PlanListViewModel(activePlan: activePlan)
        self.init(viewModel: viewModel)
    }

    private init(viewModel: PlanListViewModel) {
        self.viewModel = viewModel
        super.init(style: .Grouped)
        title = NSLocalizedString("Plans", comment: "Title for the plan selector")
        restorationIdentifier = PlanListViewController.restorationIdentifier
        restorationClass = PlanListViewController.self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
        ImmuTable.registerRows([PlanListRow.self], tableView: tableView)
        handler.viewModel = viewModel.tableViewModel
    }
}

extension PlanListViewModel: Equatable {}
func ==(lhs: PlanListViewModel, rhs: PlanListViewModel) -> Bool {
    return lhs.activePlan == rhs.activePlan
}

/*
 Since PlanListViewModel is a struct, it can't conform to NSCoding.
 We're just using the same naming for convenience.
 */
extension PlanListViewModel/*: NSCoding */ {
    struct EncodingKey {
        static let activePlan = "activePlan"

    }
    func encodeWithCoder(aCoder: NSCoder) {
        if let plan = activePlan {
            aCoder.encodeInteger(plan.rawValue, forKey: EncodingKey.activePlan)
        }
    }

    init(coder aDecoder: NSCoder) {
        let planID: Int? = {
            guard aDecoder.containsValueForKey(EncodingKey.activePlan) else {
                return nil
            }
            return aDecoder.decodeIntegerForKey(EncodingKey.activePlan)
        }()

        let plan = planID.flatMap({ Plan(rawValue: $0) })
        self.init(activePlan: plan)
    }
}

extension PlanListViewController: UIViewControllerRestoration {
    static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        guard let identifier = identifierComponents.last as? String where identifier == PlanListViewController.restorationIdentifier else {
            return nil
        }

        let viewModel = PlanListViewModel(coder: coder)
        return PlanListViewController(viewModel: viewModel)
    }

    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        viewModel.encodeWithCoder(coder)
    }
}
