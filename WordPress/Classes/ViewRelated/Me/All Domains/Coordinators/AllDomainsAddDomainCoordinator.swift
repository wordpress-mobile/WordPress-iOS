import Foundation

@objc final class AllDomainsAddDomainCoordinator: NSObject {
    static func presentAddDomainFlow(in allDomainsViewController: AllDomainsListViewController) {
        let coordinator = RegisterDomainCoordinator(site: nil, analyticsSource: "all_domains")
        let domainSuggestionsViewController = RegisterDomainSuggestionsViewController.instance(
            coordinator: coordinator,
            domainSelectionType: .purchaseFromDomainManagement,
            includeSupportButton: false,
            title: Strings.searchTitle)


        let domainPurchasedCallback = { (domainViewController: UIViewController, domainName: String) in
            domainViewController.dismiss(animated: true) {
                allDomainsViewController.reloadDomains()
            }
        }

        let domainAddedToCart = FreeToPaidPlansCoordinator.plansFlowAfterDomainAddedToCartBlock(
            customTitle: RegisterDomainCoordinator.TextContent.checkoutTitle,
            purchaseCallback: domainPurchasedCallback)

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
