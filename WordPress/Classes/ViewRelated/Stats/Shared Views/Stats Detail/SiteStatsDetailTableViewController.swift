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

        guard let statSection = statSection else {
            return ImmuTable(sections: [])
        }

        var tableRows = [ImmuTableRow]()

        // TODO: populate table with real data.
        // This is fake just to example the table.
        if let siteStatsInsightsDelegate = siteStatsInsightsDelegate {
            tableRows.append(TopTotalsInsightStatsRow(itemSubtitle: statSection.itemSubtitle,
                                                      dataSubtitle: statSection.dataSubtitle,
                                                      dataRows: mockRows(),
                                                      siteStatsInsightsDelegate: siteStatsInsightsDelegate))
        }

        if let siteStatsPeriodDelegate = siteStatsPeriodDelegate {
            tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: statSection.itemSubtitle,
                                     dataSubtitle: statSection.dataSubtitle,
                                     dataRows: mockRows(),
                                     siteStatsPeriodDelegate: siteStatsPeriodDelegate))
        }

        tableRows.append(TableFooterRow())

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [TopTotalsInsightStatsRow.self, TableFooterRow.self]
    }


    func mockRows() -> [StatsTotalRowData] {
        var dataRows = [StatsTotalRowData]()

            dataRows.append(StatsTotalRowData.init(name: "Row 1",
                                                   data: 99999.abbreviatedString(),
                                                   icon: Style.imageForGridiconType(.mySites)))


            dataRows.append(StatsTotalRowData.init(name: "Row 2",
                                                   data: 666.abbreviatedString(),
                                                   icon: Style.imageForGridiconType(.mySites)))

            dataRows.append(StatsTotalRowData.init(name: "Rows 3",
                                                   data: 1010101010.abbreviatedString(),
                                                   icon: Style.imageForGridiconType(.mySites)))

        return dataRows
    }

}
