import Foundation
import WordPressShared
import WordPressUI

enum PlanListViewModel {
    case loading
    case ready([Plan], [PlanFeature])
    case error

    var noResultsViewModel: NoResultsViewController.Model? {
        switch self {
        case .loading:
            return NoResultsViewController.Model(title: NSLocalizedString("Loading Plans...", comment: "Text displayed while loading plans details"),
                                                 accessoryView: PlansLoadingIndicatorView())
        case .ready:
            return nil
        case .error:
            return NoResultsViewController.Model(title: NSLocalizedString("Oops", comment: "An informal exclaimation that means `something went wrong`."),
                                                 subtitle: NSLocalizedString("There was an error loading plans", comment: "Text displayed when there is a failure loading the plan list"),
                                                 buttonText: NSLocalizedString("Contact support", comment: "Button label for contacting support"))
        }
    }

    func tableViewModelWithPresenter(_ presenter: ImmuTablePresenter?) -> ImmuTable {
        switch self {

        case .loading, .error:
            return ImmuTable.Empty

        case .ready(let plans, let features):

            let rows: [ImmuTableRow] = plans.map({ plan in

                var action: ImmuTableAction? = nil
                if let presenter = presenter {
                    action = presenter.present(self.controllerForPlanDetails(plans, plan: plan, features: features))
                }

                return PlanListRow(
                    title: plan.name,
                    description: plan.tagline,
                    icon: plan.icon,
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

    func controllerForPlanDetails(_ plans: [Plan], plan: Plan, features: [PlanFeature]) -> ImmuTableRowControllerGenerator {
        return { row in
            WPAppAnalytics.track(.openedPlansComparison)

            let planVC = PlanComparisonViewController(plans: plans, initialPlan: plan, features: features)
            let navigationVC = RotationAwareNavigationViewController(rootViewController: planVC)
            navigationVC.modalPresentationStyle = .formSheet
            return navigationVC
        }
    }

}
