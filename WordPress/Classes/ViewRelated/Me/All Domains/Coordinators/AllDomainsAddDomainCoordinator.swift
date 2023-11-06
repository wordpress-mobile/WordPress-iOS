import Foundation

@objc final class AllDomainsAddDomainCoordinator: NSObject {
    static func presentAddDomainFlow(in allDomainsViewController: AllDomainsListViewController,
                                     source: String) {
        let coordinator = RegisterDomainCoordinator(site: nil)
        let domainSuggestionsViewController = RegisterDomainSuggestionsViewController.instance(
            coordinator: coordinator,
            domainSelectionType: .purchaseFromDomainManagement,
            includeSupportButton: false,
            title: Strings.searchTitle)


        let domainPurchasedCallback = { (domainViewController: UIViewController, domainName: String) in
            allDomainsViewController.reloadDomains()
        }

        domainSuggestionsViewController.domainPurchasedCallback = domainPurchasedCallback

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
