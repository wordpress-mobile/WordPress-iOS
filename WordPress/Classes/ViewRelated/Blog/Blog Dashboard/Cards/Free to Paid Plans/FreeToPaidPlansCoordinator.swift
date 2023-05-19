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
            // TODO: Present Plans Selection and Checkout Flow
            // https://github.com/wordpress-mobile/WordPress-iOS/issues/20688
        }

        dashboardViewController.show(domainSuggestionsViewController, sender: nil)
    }
}
