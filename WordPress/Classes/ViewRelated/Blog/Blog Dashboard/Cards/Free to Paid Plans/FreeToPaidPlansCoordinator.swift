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

        domainSuggestionsViewController.domainAddedToCartCallback = {
            guard let viewModel = PlanSelectionViewModel(blog: blog) else { return }
            let planSelectionViewController = PlanSelectionViewController(viewModel: viewModel)
            navigationController.pushViewController(planSelectionViewController, animated: true)

            PlansTracker.trackPlanSelectionWebViewViewed(.domainAndPlanPackage, source: "domains_register")
        }

        dashboardViewController.present(navigationController, animated: true)
    }
}
