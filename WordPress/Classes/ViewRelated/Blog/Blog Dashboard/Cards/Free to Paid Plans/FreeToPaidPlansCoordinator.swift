import UIKit
import SwiftUI

@objc final class FreeToPaidPlansCoordinator: NSObject {
    static func presentFreeDomainWithAnnualPlanFlow(
        in dashboardViewController: BlogDashboardViewController,
        source: String,
        blog: Blog
    ) {
        let coordinator = RegisterDomainCoordinator(site: blog)
        let domainSuggestionsViewController = RegisterDomainSuggestionsViewController.instance(
            coordinator: coordinator,
            domainSelectionType: .purchaseWithPaidPlan,
            includeSupportButton: false
        )

        let purchaseCallback = { (checkoutViewController: CheckoutViewController, domainName: String) in

            let blogService = BlogService(coreDataStack: ContextManager.shared)
            blogService.syncBlogAndAllMetadata(blog) { }

            let resultView = DomainResultView(domain: domainName) {
                dashboardViewController.dismiss(animated: true)
                dashboardViewController.reloadCardsLocally()
            }
            let viewController = UIHostingController(rootView: resultView)
            checkoutViewController.navigationController?.setNavigationBarHidden(true, animated: false)
            checkoutViewController.navigationController?.pushViewController(viewController, animated: true)

            PlansTracker.trackPurchaseResult(source: "plan_selection")
        }

        let planSelected = { (planSelectionViewController: PlanSelectionViewController, domainName: String, checkoutURL: URL) in
            let viewModel = CheckoutViewModel(url: checkoutURL)
            let checkoutViewController = CheckoutViewController(viewModel: viewModel, purchaseCallback: { checkoutViewController in
                purchaseCallback(checkoutViewController, domainName)
            })
            checkoutViewController.configureSandboxStore {
                planSelectionViewController.navigationController?.pushViewController(checkoutViewController, animated: true)
            }
        }

        let domainAddedToCart = { (domainViewController: UIViewController, domainName: String) in
            guard let viewModel = PlanSelectionViewModel(blog: blog) else { return }
            let planSelectionViewController = PlanSelectionViewController(viewModel: viewModel)
            planSelectionViewController.planSelectedCallback = { planSelectionViewController, checkoutURL in
                planSelected(planSelectionViewController, domainName, checkoutURL)
            }
            domainViewController.navigationController?.pushViewController(planSelectionViewController, animated: true)
        }
        coordinator.domainAddedToCartCallback = domainAddedToCart

        let navigationController = UINavigationController(rootViewController: domainSuggestionsViewController)
        dashboardViewController.present(navigationController, animated: true)
    }
}
