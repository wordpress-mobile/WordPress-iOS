import Foundation
import WordPressShared

enum PlanListViewModel {
    case Loading
    case Ready(SitePricedPlans)
    case Error(String)

    var noResultsViewModel: WPNoResultsView.Model? {
        switch self {
        case .Loading:
            return WPNoResultsView.Model(
                title: NSLocalizedString("Loading Plans...", comment: "Text displayed while loading plans details"),
                accessoryView: PlansLoadingIndicatorView()
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

    func tableFooterViewModelWithPresenter(presenter: UIViewController) -> (title: String, action: () -> Void)? {
        switch self {
        case .Ready:
            // Currently unused as we've removed the terms and conditions footer until we re-add purchasing at a later date
            let _ = { [weak presenter] in
                let webViewController = WPWebViewController(URL: NSURL(string: WPAutomatticTermsOfServiceURL)!)
                let navController = UINavigationController(rootViewController: webViewController)
                presenter?.presentViewController(navController, animated: true, completion: nil)
            }

            return (footerTitle, {})
        default:
            return nil
        }
    }

    // Currently unused until we re-add purchasing at a later date
    private var termsAndConditionsFooterTitle: NSAttributedString {
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

    private var footerTitle: String {
        return NSLocalizedString("You can manage your current plan at WordPress.com/plans", comment: "Footer for Plans list")
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
                    rows: rows,
                    footerText: NSLocalizedString("Manage your plan at WordPress.com/plans", comment: "Footer for Plans list"))
                ])
        }
    }

    func controllerForPlanDetails(sitePricedPlans: SitePricedPlans, initialPlan: Plan, planService: PlanService<StoreKitStore>) -> ImmuTableRowControllerGenerator {
        return { row in
            WPAppAnalytics.track(.OpenedPlansComparison)
            let planVC = PlanComparisonViewController(sitePricedPlans: sitePricedPlans, initialPlan: initialPlan, service: planService)
            let navigationVC = RotationAwareNavigationViewController(rootViewController: planVC)
            navigationVC.modalPresentationStyle = .FormSheet
            return navigationVC
        }
    }
}
