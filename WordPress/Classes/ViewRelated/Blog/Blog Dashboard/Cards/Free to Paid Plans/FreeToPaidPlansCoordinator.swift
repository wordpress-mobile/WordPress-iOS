import UIKit
import SwiftUI

@objc final class FreeToPaidPlansCoordinator: NSObject {

    typealias PurchaseCallback = ((UIViewController, String) -> Void)

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

        let purchaseCallback = { (checkoutViewController: UIViewController, domainName: String) in

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

        let domainAddedToCart = plansFlowAfterDomainAddedToCartBlock(customTitle: nil, purchaseCallback: purchaseCallback)

        coordinator.domainAddedToCartCallback = domainAddedToCart

        let navigationController = UINavigationController(rootViewController: domainSuggestionsViewController)
        dashboardViewController.present(navigationController, animated: true)
    }

    /// Creates a block that launches the plans selection flow after a domain is added to the user's shopping cart
    /// - Parameters:
    ///   - customTitle: Title of of the presented view. If nil the title displays the title of the webview..
    ///   - purchaseCallback: closure to be called when user completes a plan purchase.
    static func plansFlowAfterDomainAddedToCartBlock(customTitle: String?,
                                                     purchaseCallback: @escaping PurchaseCallback) -> RegisterDomainCoordinator.DomainAddedToCartCallback {
        let planSelected = { (planSelectionViewController: PlanSelectionViewController, domainName: String, checkoutURL: URL) in
            let viewModel = CheckoutViewModel(url: checkoutURL)
            let checkoutViewController = CheckoutViewController(viewModel: viewModel, customTitle: customTitle, purchaseCallback: { checkoutViewController in
                purchaseCallback(checkoutViewController, domainName)
            })
            checkoutViewController.configureSandboxStore {
                planSelectionViewController.navigationController?.pushViewController(checkoutViewController, animated: true)
            }
        }

        let domainAddedToCart = { (domainViewController: UIViewController, domainName: String, blog: Blog) in
            guard let viewModel = PlanSelectionViewModel(blog: blog) else { return }
            let planSelectionViewController = PlanSelectionViewController(viewModel: viewModel, customTitle: customTitle)
            planSelectionViewController.planSelectedCallback = { planSelectionViewController, checkoutURL in
                planSelected(planSelectionViewController, domainName, checkoutURL)
            }
            domainViewController.navigationController?.pushViewController(planSelectionViewController, animated: true)
        }
        return domainAddedToCart
    }
}
