import Foundation
import WordPressShared
import WordPressUI


enum PlanListViewModel {
    case loading
    case ready(SitePricedPlans)
    case error(String)

    var noResultsViewModel: NoResultsViewController.Model? {
        switch self {
        case .loading:
            return NoResultsViewController.Model(title: NSLocalizedString("Loading Plans...", comment: "Text displayed while loading plans details"),
                                                 accessoryView: PlansLoadingIndicatorView())
        case .ready:
            return nil
        case .error:
            let appDelegate = WordPressAppDelegate.sharedInstance()
            if (appDelegate?.connectionAvailable)! {
                return NoResultsViewController.Model(title: NSLocalizedString("Oops", comment: ""),
                                                     subtitle: NSLocalizedString("There was an error loading plans", comment: ""),
                                                     buttonText: NSLocalizedString("Contact support", comment: ""))
            } else {
                return NoResultsViewController.Model(title: NSLocalizedString("No connection", comment: "Title for the error view when there's no connection"),
                                                     subtitle: NSLocalizedString("An active internet connection is required to view plans", comment: ""))
            }
        }
    }

    func tableFooterViewModelWithPresenter(_ presenter: UIViewController) -> (title: String, action: () -> Void)? {
        switch self {
        case .ready:
            // Currently unused as we've removed the terms and conditions footer until we re-add purchasing at a later date
            let _ = { [weak presenter] in
                let url = URL(string: WPAutomatticTermsOfServiceURL)!
                let webViewController = WebViewControllerFactory.controller(url: url)
                let navController = UINavigationController(rootViewController: webViewController)
                presenter?.present(navController, animated: true, completion: nil)
            }

            return (footerTitle, {})
        default:
            return nil
        }
    }

    // Currently unused until we re-add purchasing at a later date
    fileprivate var termsAndConditionsFooterTitle: NSAttributedString {
        let bodyColor = WPStyleGuide.greyDarken10()
        let linkColor = WPStyleGuide.wordPressBlue()

        // Non-breaking space entity prevents an orphan word if the text wraps
        let tos = NSLocalizedString("By checking out, you agree to our <a>fascinating terms and&nbsp;conditions</a>.", comment: "Terms of Service link displayed when a user is making a purchase. Text inside <a> tags will be highlighted.")

        let attributes: StyledHTMLAttributes = [ .BodyAttribute: [ .font: UIFont.systemFont(ofSize: 12),
                                                                   .foregroundColor: bodyColor ],
                                                 .ATagAttribute: [ .underlineStyle: NSUnderlineStyle.styleNone.rawValue,
                                                                   .foregroundColor: linkColor] ]

        let attributedTos = NSAttributedString.attributedStringWithHTML(tos, attributes: attributes)

        return attributedTos
    }

    fileprivate var footerTitle: String {
        return NSLocalizedString("You can manage your current plan at WordPress.com/plans", comment: "Footer for Plans list")
    }

    func tableViewModelWithPresenter(_ presenter: ImmuTablePresenter?, planService: PlanService<StoreKitStore>?) -> ImmuTable {
        switch self {
        case .loading, .error:
            return ImmuTable.Empty
        case .ready(let siteID, let activePlan, let plans):
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
                    footerText: String())
                ])
        }
    }

    func controllerForPlanDetails(_ sitePricedPlans: SitePricedPlans, initialPlan: Plan, planService: PlanService<StoreKitStore>) -> ImmuTableRowControllerGenerator {
        return { row in
            WPAppAnalytics.track(.openedPlansComparison)
            let planVC = PlanComparisonViewController(sitePricedPlans: sitePricedPlans, initialPlan: initialPlan, service: planService)
            let navigationVC = RotationAwareNavigationViewController(rootViewController: planVC)
            navigationVC.modalPresentationStyle = .formSheet
            return navigationVC
        }
    }
}
