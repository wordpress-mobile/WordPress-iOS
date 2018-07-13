import UIKit

class RegisterDomainDetailsViewController: UITableViewController {

    private var tableHandler: ImmuTableViewHandler!

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    private func configure() {
        configureTableView()
        configureNavigationBar()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    private func configureTableView() {
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        // remove empty cells
        tableView.tableFooterView = UIView()

    }

    private func configureNavigationBar() {
        title = NSLocalizedString("Register domain",
                                  comment: "Title for the Register domain screen")
        addCancelBarButtonItem()
    }

    private func addCancelBarButtonItem() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Cancel",
                                     comment: "Navigation bar cancel button for Register domain screen"),
            style: .plain,
            target: self,
            action: #selector(cancelBarButtonTapped)
        )
    }

    static func instance() -> RegisterDomainDetailsViewController {
        let storyboard = UIStoryboard(name: "Domains", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "RegisterDomainDetailsViewController") as! RegisterDomainDetailsViewController
        return controller
    }

    // MARK: - Actions

    @objc private func cancelBarButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
