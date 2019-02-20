import UIKit

class SiteStatsDetailTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = "SiteStatsDetailTableViewController"

    // MARK: - Properties

    private typealias Style = WPStyleGuide.Stats

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()

        title = "This Be The Deets"
//        title = NSLocalizedString("title", comment: "Title for stats detail view.")
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: SiteStatsDetailTableHeaderView.identifier
            ) as? SiteStatsDetailTableHeaderView else {
                return nil
        }

        headerView.configure()
        return headerView
    }

}

// MARK: - Table Methods

private extension SiteStatsDetailTableViewController {

    func setupTable() {
        tableView.estimatedSectionHeaderHeight = 300
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        tableView.register(
            UINib(nibName: SiteStatsDetailTableHeaderView.identifier, bundle: nil),
            forHeaderFooterViewReuseIdentifier: SiteStatsDetailTableHeaderView.identifier
        )

        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        tableHandler.viewModel = tableViewModel()
    }

    func tableViewModel() -> ImmuTable {
        return ImmuTable(sections: [
            ImmuTableSection(
                rows: [
                ])
            ])
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return []
    }

}
