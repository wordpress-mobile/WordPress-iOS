import UIKit

final class MyDomainsViewController: UIViewController {
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

extension MyDomainsViewController {
    enum Strings {
        static let title = NSLocalizedString(
            "domain.management.title",
            value: "My Domains",
            comment: "Domain Management Screen Title"
        )
    }
}
