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

        coordinator.domainPurchasedCallback = domainPurchasedCallback // For no site flow (domain only)

        let navigationController = UINavigationController(rootViewController: domainSuggestionsViewController)
        navigationController.isModalInPresentation = true
        allDomainsViewController.present(navigationController, animated: true)
    }
}
