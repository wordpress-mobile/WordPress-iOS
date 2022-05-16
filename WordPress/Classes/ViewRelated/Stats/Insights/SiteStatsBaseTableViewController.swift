import UIKit

/// Base class for site stats table view controllers
///

class SiteStatsBaseTableViewController: UIViewController {

    let refreshControl = UIRefreshControl()

    // MARK: - Properties
    lazy var tableView: UITableView = {
        UITableView(frame: .zero, style: FeatureFlag.statsNewAppearance.enabled ? .insetGrouped : .plain)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        initTableView()
    }

    func initTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.pinSubviewToAllEdges(tableView)

        tableView.refreshControl = refreshControl
    }
}

// MARK: - Tableview Datasource

// These methods aren't actually needed as the tableview is controlled by an instance of ImmuTableViewHandler.
// However, ImmuTableViewHandler requires that the owner of the tableview is a data source and delegate.

extension SiteStatsBaseTableViewController: TableViewContainer, UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
