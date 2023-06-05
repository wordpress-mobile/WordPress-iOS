import UIKit
import SwiftUI

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

        let purchaseCallback = { (domainName: String) in

            let blogService = BlogService(coreDataStack: ContextManager.shared)
            blogService.syncBlogAndAllMetadata(blog) { }

            let resultView = DomainResultView(domain: domainName) {
                dashboardViewController.dismiss(animated: true)
                dashboardViewController.reloadCardsLocally()
            }
            let viewController = UIHostingController(rootView: resultView)
            navigationController.setNavigationBarHidden(true, animated: false)
            navigationController.pushViewController(viewController, animated: true)

            PlansTracker.trackPurchaseResult(source: "plan_selection")
        }

        let planSelected = { (domainName: String, checkoutURL: URL) in
            let viewModel = CheckoutViewModel(url: checkoutURL)
            let checkoutViewController = CheckoutViewController(viewModel: viewModel, purchaseCallback: {
                purchaseCallback(domainName)
            })
            checkoutViewController.configureSandboxStore {
                navigationController.pushViewController(checkoutViewController, animated: true)
            }

            PlansTracker.trackCheckoutWebViewViewed(source: "plan_selection")
        }

        let domainAddedToCart = { (domainName: String) in
            guard let viewModel = PlanSelectionViewModel(blog: blog) else { return }
            let planSelectionViewController = PlanSelectionViewController(viewModel: viewModel)
            planSelectionViewController.planSelectedCallback = { checkoutURL in
                planSelected(domainName, checkoutURL)
            }
            navigationController.pushViewController(planSelectionViewController, animated: true)

            PlansTracker.trackPlanSelectionWebViewViewed(.domainAndPlanPackage, source: "domains_register")
        }
        domainSuggestionsViewController.domainAddedToCartCallback = domainAddedToCart

        dashboardViewController.present(navigationController, animated: true)
    }
}
