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

    let action: ImmuTableAction?

    func configureCell(cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.imageView?.image = icon
        cell.textLabel?.attributedText = attributedTitle
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.text = description
        cell.detailTextLabel?.textColor = WPStyleGuide.grey()
        cell.separatorInset = UIEdgeInsetsZero
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
            NSFontAttributeName: WPFontManager.systemRegularFontOfSize(14.0),
            NSForegroundColorAttributeName: WPStyleGuide.darkGrey()
        ]
        static let pricePeriodAttributes = [
            NSFontAttributeName: WPFontManager.systemItalicFontOfSize(13.0),
            NSForegroundColorAttributeName: WPStyleGuide.greyLighten20()
        ]

        static func attributedTitle(title: String, price: String, active: Bool) -> NSAttributedString {
            let planTitle = NSAttributedString(string: title, attributes: titleAttributes)

            let attributedTitle = NSMutableAttributedString(attributedString: planTitle)

            if active {
                let currentPlanAttributes = [
                    NSFontAttributeName: WPFontManager.systemSemiBoldFontOfSize(11.0),
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

enum PlanListViewModel {
    case Loading
    case Ready(SitePricedPlans)
    case Error(String)

    var noResultsViewModel: WPNoResultsView.Model? {
        switch self {
        case .Loading:
            return WPNoResultsView.Model(
                title: NSLocalizedString("Loading Plans...", comment: "Text displayed while loading plans details")
            )
        case .Ready(_):
            return nil
        case .Error(_):
            return WPNoResultsView.Model(
                title: NSLocalizedString("Oops", comment: ""),
                message: NSLocalizedString("There was an error loading plans", comment: ""),
                buttonTitle: NSLocalizedString("Contact support", comment: "")
            )
        }
    }

    func tableViewModelWithPresenter(presenter: ImmuTablePresenter?, planService: PlanService?) -> ImmuTable {
        switch self {
        case .Loading, .Error(_):
            return ImmuTable.Empty
        case .Ready(let activePlan, let plans):
            let rows: [ImmuTableRow] = plans.map({ (plan, price) in
                let active = (activePlan == plan)
                let icon = active ? plan.activeImage : plan.image
                var action: ImmuTableAction? = nil
                if let presenter = presenter,
                    let planService = planService {
                    action = presenter.present(self.controllerForPlanDetails(plan, activePlan: activePlan, planService: planService))
                }
                
                return PlanListRow(
                    title: plan.title,
                    active: active,
                    price: price,
                    description: plan.description,
                    icon: icon,
                    action: action
                )
            })
            return ImmuTable(sections: [
                ImmuTableSection(
                    headerText: NSLocalizedString("WordPress.com Plans", comment: "Title for the Plans list header"),
                    rows: rows)
                ])
        }
    }

    func controllerForPlanDetails(plan: Plan, activePlan: Plan, planService: PlanService) -> ImmuTableRowControllerGenerator {
        return { row in
            let planVC = PlanComparisonViewController.controllerWithInitialPlan(plan, activePlan: activePlan, planService: planService)
            let navigationVC = RotationAwareNavigationViewController(rootViewController: planVC)
            navigationVC.modalPresentationStyle = .FormSheet
            return navigationVC
        }
    }
}

final class PlanListViewController: UITableViewController, ImmuTablePresenter {
    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()
    private var viewModel: PlanListViewModel = .Loading {
        didSet {
            handler.viewModel = viewModel.tableViewModelWithPresenter(self, planService: service)
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

    static let restorationIdentifier = "PlanList"

    convenience init(blog: Blog) {
        precondition(blog.dotComID != nil)
        let service = PlanService(blog: blog)
        self.init(siteID: Int(blog.dotComID), service: service)
    }

    let siteID: Int
    let service: PlanService
    init(siteID: Int, service: PlanService) {
        self.siteID = siteID
        self.service = service
        super.init(style: .Grouped)
        title = NSLocalizedString("Plans", comment: "Title for the plan selector")
        restorationIdentifier = PlanListViewController.restorationIdentifier
        restorationClass = PlanListViewController.self
        noResultsView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
        ImmuTable.registerRows([PlanListRow.self], tableView: tableView)
        handler.viewModel = viewModel.tableViewModelWithPresenter(self, planService: service)
        updateNoResults()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        service.plansWithPricesForBlog(siteID, success: { result in
            self.viewModel = .Ready(result)
            }, failure: { error in
                self.viewModel = .Error(String(error))
        })
    }
}

// MARK: - WPNoResultsViewDelegate

extension PlanListViewController: WPNoResultsViewDelegate {
    func didTapNoResultsView(noResultsView: WPNoResultsView!) {
        SupportViewController.showFromTabBar()
    }
}

// MARK: - UIViewControllerRestoration

extension PlanListViewController: UIViewControllerRestoration {
    struct EncodingKey {
        static let activePlan = "activePlan"
    }
    static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        guard let identifier = identifierComponents.last as? String where identifier == PlanListViewController.restorationIdentifier else {
            return nil
        }

        // TODO: postpone restoration until view model is stable
        // @koke 2016-03-01
        return nil
    }

    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
    }
}
