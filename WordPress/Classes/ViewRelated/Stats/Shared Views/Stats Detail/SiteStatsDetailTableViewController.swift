import UIKit

class SiteStatsDetailTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = "SiteStatsDetailTableViewController"

    // MARK: - Properties

    private typealias Style = WPStyleGuide.Stats
    private var statSection: StatSection?
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

        setupTable()
        title = statSection.title
    }

}

// MARK: - Table Methods

private extension SiteStatsDetailTableViewController {

    func setupTable() {
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        tableHandler.viewModel = tableViewModel()
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [TopTotalsInsightStatsRow.self,
                TopTotalsPeriodStatsRow.self,
                CountriesStatsRow.self,
                TableFooterRow.self]
    }

    func tableViewModel() -> ImmuTable {

        guard let statSection = statSection else {
            return ImmuTable(sections: [])
        }

        var tableRows = [ImmuTableRow]()

        if StatSection.allInsights.contains(statSection),
            let insightRow = insightRow() {
            tableRows.append(insightRow)
        }

        if StatSection.allPeriods.contains(statSection),
            let periodRow = periodRow() {
            tableRows.append(periodRow)
        }

        tableRows.append(TableFooterRow())

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

    func insightRow() -> ImmuTableRow? {

        guard let siteStatsInsightsDelegate = siteStatsInsightsDelegate,
            let statSection = statSection else {
                return nil
        }

        switch statSection {
        default:
            return TopTotalsInsightStatsRow(itemSubtitle: statSection.itemSubtitle,
                                           dataSubtitle: statSection.dataSubtitle,
                                           dataRows: mockRows(),
                                           siteStatsInsightsDelegate: siteStatsInsightsDelegate)
        }
    }

    func periodRow() -> ImmuTableRow? {

        guard let siteStatsPeriodDelegate = siteStatsPeriodDelegate,
        let statSection = statSection else {
            return nil
        }

        switch statSection {
        case .periodCountries:
            return CountriesStatsRow(itemSubtitle: statSection.itemSubtitle,
                                     dataSubtitle: statSection.dataSubtitle,
                                     dataRows: mockRows(),
                                     siteStatsPeriodDelegate: siteStatsPeriodDelegate)
        default:
            return TopTotalsPeriodStatsRow(itemSubtitle: statSection.itemSubtitle,
                                           dataSubtitle: statSection.dataSubtitle,
                                           dataRows: mockRows(),
                                           siteStatsPeriodDelegate: siteStatsPeriodDelegate)
        }


    }

    // TODO: populate table with real data.
    // This is fake just to example the table.

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
