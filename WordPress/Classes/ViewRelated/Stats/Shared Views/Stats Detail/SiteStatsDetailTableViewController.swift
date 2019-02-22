import UIKit

class SiteStatsDetailTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = "SiteStatsDetailTableViewController"

    // MARK: - Properties

    private typealias Style = WPStyleGuide.Stats
    private var statSection: StatSection?
    private var showHeader = false
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private weak var siteStatsPeriodDelegate: SiteStatsPeriodDelegate?

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func configure(statSection: StatSection,
                   siteStatsInsightsDelegate: SiteStatsInsightsDelegate? = nil,
                   siteStatsPeriodDelegate: SiteStatsPeriodDelegate? = nil) {
        self.statSection = statSection
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate
        self.siteStatsPeriodDelegate = siteStatsPeriodDelegate

        showHeader = statSection == .periodCountries || StatSection.tabbedSections.contains(statSection)
        setupTable()
        title = statSection.title
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        guard showHeader,
            let statSection = statSection,
            let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: SiteStatsDetailTableHeaderView.identifier
            ) as? SiteStatsDetailTableHeaderView else {
                return nil
        }

        headerView.configure(statSection: statSection)
        return headerView
    }

}

// MARK: - Table Methods

private extension SiteStatsDetailTableViewController {

    func setupTable() {
        if showHeader {
            tableView.estimatedSectionHeaderHeight = 300
            tableView.sectionHeaderHeight = UITableView.automaticDimension

            tableView.register(
                UINib(nibName: SiteStatsDetailTableHeaderView.identifier, bundle: nil),
                forHeaderFooterViewReuseIdentifier: SiteStatsDetailTableHeaderView.identifier
            )
        }

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
