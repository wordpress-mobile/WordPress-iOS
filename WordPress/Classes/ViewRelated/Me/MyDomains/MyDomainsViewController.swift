import UIKit

final class MyDomainsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.title

        WPStyleGuide.configureColors(view: view, tableView: nil)
        let action = UIAction { [weak self] _ in
            let viewController = DomainsDashboardFactory.makeDomainsSuggestionViewController(
                blog: Blog(context: ContextManager.shared.mainContext),
                domainSelectionType: .registerWithPaidPlan) {
                    print("** DISMISSED **")
                }
            let navigationController = UINavigationController(rootViewController: viewController)
            self?.present(navigationController, animated: true)
        }
        navigationItem.rightBarButtonItem = .init(systemItem: .add, primaryAction: action)
    }
}

extension MyDomainsViewController {
    enum Strings {
        static let title = NSLocalizedString(
            "domain.management.title",
            value: "My Domains",
            comment: "Domain Management Screen Title"
        )
    }
}
