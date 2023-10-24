import UIKit

final class MyDomainsViewController: UIViewController {
    enum Action: String {
        case addToSite
        case purchase
        case transfer

        var title: String {
            switch self {
            case .addToSite:
                return NSLocalizedString(
                    "domain.management.fab.add.domain.title",
                    value: "Add domain to site",
                    comment: "Domain Management FAB Add Domain title"
                )
            case .purchase:
                return NSLocalizedString(
                    "domain.management.fab.purchase.domain.title",
                    value: "Purchase domain only",
                    comment: "Domain Management FAB Purchase Domain title"
                )
            case .transfer:
                return NSLocalizedString(
                    "domain.management.fab.transfer.domain.title",
                    value: "Transfer domain(s)",
                    comment: "Domain Management FAB Transfer Domain title"
                )
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.title

        WPStyleGuide.configureColors(view: view, tableView: nil)
        let action = UIAction { _ in
            // Present add domain screen.
        }
        navigationItem.rightBarButtonItem = .init(systemItem: .add, primaryAction: action)
    }
}

private extension MyDomainsViewController {
    enum Strings {
        static let title = NSLocalizedString(
            "domain.management.title",
            value: "My Domains",
            comment: "Domain Management Screen Title"
        )
    }
}
