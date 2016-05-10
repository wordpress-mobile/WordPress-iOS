import UIKit
import WordPressShared

struct PlanListRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellSubtitle)
    static let customHeight: Float? = 92
    private let iconSize = CGSize(width: 60, height: 60)

    let title: String
    let active: Bool
    let price: String
    let description: String
    let iconUrl: NSURL

    let action: ImmuTableAction?

    func configureCell(cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.imageView?.downloadResizedImage(iconUrl, placeholderImage: UIImage(named: "plan-placeholder")!, pointSize: iconSize)
        cell.textLabel?.attributedText = attributedTitle
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.text = description
        cell.detailTextLabel?.textColor = WPStyleGuide.grey()
        cell.detailTextLabel?.font = WPFontManager.systemRegularFontOfSize(14.0)
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
            NSFontAttributeName: WPFontManager.systemItalicFontOfSize(14.0),
            NSForegroundColorAttributeName: WPStyleGuide.grey()
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

                let pricePeriod = String(format: NSLocalizedString("%@ <em>per year</em>", comment: "Plan yearly price"), price)

                let attributes: StyledHTMLAttributes = [ .BodyAttribute: priceAttributes,
                                                         .EmTagAttribute: pricePeriodAttributes ]

                let attributedPricePeriod = NSAttributedString.attributedStringWithHTML(pricePeriod, attributes: attributes)
                attributedTitle.appendAttributedString(attributedPricePeriod)
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

    func tableFooterViewModelWithPresenter(presenter: UIViewController) -> (title: NSAttributedString, action: () -> Void)? {
        switch self {
        case .Ready:
            let action = { [weak presenter] in
                let webViewController = WPWebViewController(URL: NSURL(string: WPAutomatticTermsOfServiceURL)!)
                let navController = UINavigationController(rootViewController: webViewController)
                presenter?.presentViewController(navController, animated: true, completion: nil)
            }

            return (footerTitle, action)
        default:
            return nil
        }
    }

    private var footerTitle: NSAttributedString {
        let bodyColor = WPStyleGuide.greyDarken10()
        let linkColor = WPStyleGuide.wordPressBlue()

        // Non-breaking space entity prevents an orphan word if the text wraps
        let tos = NSLocalizedString("By checking out, you agree to our <a>fascinating terms and&nbsp;conditions</a>.", comment: "Terms of Service link displayed when a user is making a purchase. Text inside <a> tags will be highlighted.")

        let attributes: StyledHTMLAttributes = [ .BodyAttribute: [ NSFontAttributeName: UIFont.systemFontOfSize(12),
                                                                   NSForegroundColorAttributeName: bodyColor ],
                                                 .ATagAttribute: [ NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleNone.rawValue,
                                                                   NSForegroundColorAttributeName: linkColor] ]

        let attributedTos = NSAttributedString.attributedStringWithHTML(tos, attributes: attributes)

        return attributedTos
    }

    func tableViewModelWithPresenter(presenter: ImmuTablePresenter?, planService: PlanService<StoreKitStore>?) -> ImmuTable {
        switch self {
        case .Loading, .Error(_):
            return ImmuTable.Empty
        case .Ready(let siteID, let activePlan, let plans):
            let rows: [ImmuTableRow] = plans.map({ (plan, price) in
                let active = (activePlan == plan)
                let iconUrl = active ? plan.activeIconUrl : plan.iconUrl
                var action: ImmuTableAction? = nil
                if let presenter = presenter,
                    let planService = planService {
                    let sitePricedPlans = (siteID: siteID, activePlan: activePlan, availablePlans: plans)
                    action = presenter.present(self.controllerForPlanDetails(sitePricedPlans, initialPlan: plan, planService: planService))
                }

                return PlanListRow(
                    title: plan.title,
                    active: active,
                    price: price,
                    description: plan.tagline,
                    iconUrl: iconUrl,
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

    func controllerForPlanDetails(sitePricedPlans: SitePricedPlans, initialPlan: Plan, planService: PlanService<StoreKitStore>) -> ImmuTableRowControllerGenerator {
        return { row in
            let planVC = PlanComparisonViewController(sitePricedPlans: sitePricedPlans, initialPlan: initialPlan, service: planService)
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
            updateFooterView()
        }
    }

    func updateFooterView() {
        let footerViewModel = viewModel.tableFooterViewModelWithPresenter(self)

        tableView.tableFooterView = tableFooterViewWithViewModel(footerViewModel)
    }

    private var footerTapAction: (() -> Void)?
    private func tableFooterViewWithViewModel(viewModel: (title: NSAttributedString, action: () -> Void)?) -> UIView? {
        guard let viewModel = viewModel else { return nil }

        let footerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: "ToSFooterView", style: .Footer)

        let title = viewModel.title
        footerView.attributedTitle = title
        footerView.frame.size.height = WPTableViewSectionHeaderFooterView.heightForFooter(title.string, width: footerView.bounds.width)

        // Don't add a recognizer if we already have one
        let recognizers = footerView.gestureRecognizers
        if recognizers == nil || recognizers?.count == 0 {
            footerTapAction = viewModel.action

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(footerTapped))
            footerView.addGestureRecognizer(tapRecognizer)
        }

        return footerView
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

    convenience init?(blog: Blog) {
        precondition(blog.dotComID != nil)
        guard let service = PlanService(blog: blog, store: StoreKitStore()) else {
            return nil
        }
        self.init(siteID: Int(blog.dotComID), service: service)
    }

    let siteID: Int
    let service: PlanService<StoreKitStore>
    init(siteID: Int, service: PlanService<StoreKitStore>) {
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

        service.plansWithPricesForBlog(siteID,
            success: { result in
                self.viewModel = .Ready(result)
            },
            failure: { error in
                self.viewModel = .Error(String(error))
            }
        )
    }

    func footerTapped() {
        footerTapAction?()
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
