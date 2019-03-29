import Foundation
import WordPressFlux

/// The view model used by PostStatsTableViewController to show
/// stats for a selected post.
///
class PostStatsViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()
    private var postTitle: String?

    // MARK: - Init

    init(postTitle: String?) {
        self.postTitle = postTitle
    }

    // MARK: - Table View

    func tableViewModel() -> ImmuTable {
        var tableRows = [ImmuTableRow]()

        tableRows.append(titleTableRow())
        tableRows.append(contentsOf: overviewTableRows())

        tableRows.append(TableFooterRow())

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

}

// MARK: - Private Extension

private extension PostStatsViewModel {

    // MARK: - Create Table Rows

    func titleTableRow() -> ImmuTableRow {
        return PostStatsTitleRow(postTitle: postTitle ?? NSLocalizedString("(No Title)", comment: "Empty Post Title"))
    }

    func overviewTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: ""))

        // TODO: replace with real data
        let data = OverviewTabData(tabTitle: StatSection.periodOverviewVisitors.tabTitle, tabData: 741, difference: 22222, differencePercent: 50)

        // Introduced via #11062, to be replaced with real data via #11068
        let stubbedData = SelectedPostSummaryDataStub()
        let firstStubbedDateInterval = stubbedData.summaryData.first?.date.timeIntervalSince1970 ?? 0
        let styling = SelectedPostSummaryStyling(initialDateInterval: firstStubbedDateInterval)

        let row = OverviewRow(tabsData: [data], chartData: [stubbedData], chartStyling: [styling], period: nil)
        tableRows.append(row)

        return tableRows
    }

}
