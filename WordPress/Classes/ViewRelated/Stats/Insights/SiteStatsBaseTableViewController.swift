import UIKit
import WordPressUI

/// Base class for site stats table view controllers
///
class SiteStatsBaseTableViewController: UIViewController {

    let refreshControl = UIRefreshControl()

    var tableStyle: UITableView.Style { .insetGrouped }

    private(set) lazy var tableView = UITableView(frame: .zero, style: tableStyle)

    override func viewDidLoad() {
        super.viewDidLoad()

        initTableView()
    }

    override func contentScrollView(for edge: NSDirectionalRectEdge) -> UIScrollView? {
        tableView
    }

    func initTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.cellLayoutMarginsFollowReadableWidth = true

        view.addSubview(tableView)
        tableView.pinEdges()

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

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}
