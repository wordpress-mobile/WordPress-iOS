import UIKit

@objc final class FreeToPaidPlansCoordinator: NSObject {
    static func presentFreeDomainWithAnnualPlanFlow(
        in dashboardViewController: BlogDashboardViewController,
        source: String,
        blog: Blog
    ) {
        let domainSuggestionsViewController = RegisterDomainSuggestionsViewController.instance(
            site: blog,
            domainSelectionType: .purchaseWithPaidPlan,
            includeSupportButton: false
        )

        let navigationController = UINavigationController(rootViewController: domainSuggestionsViewController)

        let planSelected = { checkoutURL in
            let viewModel = CheckoutViewModel(url: checkoutURL)
            let checkoutViewController = CheckoutViewController(viewModel: viewModel)
            checkoutViewController.configureSandboxStore {
                navigationController.pushViewController(checkoutViewController, animated: true)
            }

            PlansTracker.trackCheckoutWebViewViewed(source: "plan_selection")
        }

        let domainAddedToCart = {
            guard let viewModel = PlanSelectionViewModel(blog: blog) else { return }
            let planSelectionViewController = PlanSelectionViewController(viewModel: viewModel)
            planSelectionViewController.planSelectedCallback = planSelected
            navigationController.pushViewController(planSelectionViewController, animated: true)

            PlansTracker.trackPlanSelectionWebViewViewed(.domainAndPlanPackage, source: "domains_register")
        }
        domainSuggestionsViewController.domainAddedToCartCallback = domainAddedToCart

        dashboardViewController.present(navigationController, animated: true)
    }
}
