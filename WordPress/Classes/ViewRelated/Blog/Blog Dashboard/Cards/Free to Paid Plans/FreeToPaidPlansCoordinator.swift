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

        domainSuggestionsViewController.domainAddedToCartCallback = {
            guard let viewModel = PlanSelectionViewModel(blog: blog) else { return }
            let planSelectionViewController = PlanSelectionViewController(viewModel: viewModel)
            domainSuggestionsViewController.show(planSelectionViewController, sender: nil)

            PlansTracker.trackPlanSelectionWebViewViewed(.domainAndPlanPackage, source: "domains_register")
        }

        dashboardViewController.show(domainSuggestionsViewController, sender: nil)
    }
}
