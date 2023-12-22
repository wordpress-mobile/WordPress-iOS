import Foundation

@objc final class AllDomainsAddDomainCoordinator: NSObject {
    static func presentAddDomainFlow(in allDomainsViewController: AllDomainsListViewController) {
        let analyticsSource = AllDomainsListViewController.Constants.analyticsSource
        let coordinator = RegisterDomainCoordinator(site: nil, analyticsSource: analyticsSource)
        let domainSuggestionsViewController = DomainSelectionViewController(
            service: DomainsServiceAdapter(coreDataStack: ContextManager.shared),
            domainSelectionType: .purchaseFromDomainManagement,
            includeSupportButton: false,
            coordinator: coordinator
        )

        let domainPurchasedCallback = { (domainViewController: UIViewController, domainName: String) in
            domainViewController.dismiss(animated: true) {
                allDomainsViewController.reloadDomains()
            }
        }

        let domainAddedToCart = FreeToPaidPlansCoordinator.plansFlowAfterDomainAddedToCartBlock(
            customTitle: RegisterDomainCoordinator.TextContent.checkoutTitle,
            analyticsSource: analyticsSource
        ) { [weak coordinator] controller, domain in
            domainPurchasedCallback(controller, domain)
            coordinator?.trackDomainPurchasingCompleted()
        }

        coordinator.domainPurchasedCallback = domainPurchasedCallback // For no site flow (domain only)
        coordinator.domainAddedToCartAndLinkedToSiteCallback = domainAddedToCart // For existing site flow (plans)

        let navigationController = UINavigationController(rootViewController: domainSuggestionsViewController)
        navigationController.isModalInPresentation = true
        allDomainsViewController.present(navigationController, animated: true)
    }
}

extension AllDomainsAddDomainCoordinator {
    private enum Strings {
        static let searchTitle = NSLocalizedString("domain.management.addDomain.search.title",
                                                   value: "Search for a domain",
                                                   comment: "Search domain - Title for the Suggested domains screen")
    }
}
