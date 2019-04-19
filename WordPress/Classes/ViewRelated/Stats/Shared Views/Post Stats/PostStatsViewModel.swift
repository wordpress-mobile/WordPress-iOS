import Foundation
import WordPressFlux

/// The view model used by PostStatsTableViewController to show
/// stats for a selected post.
///
class PostStatsViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    private var postID: Int?
    private var postTitle: String?
    private var postURL: URL?
    private weak var postStatsDelegate: PostStatsDelegate?

    private let store = StoreContainer.shared.statsPeriod
    private var receipt: Receipt?
    private var changeReceipt: Receipt?

    // MARK: - Init

    init(postID: Int,
         postTitle: String?,
         postURL: URL?,
         postStatsDelegate: PostStatsDelegate) {
        self.postID = postID
        self.postTitle = postTitle
        self.postURL = postURL
        self.postStatsDelegate = postStatsDelegate

        receipt = store.query(.postStats(postID: postID))

        changeReceipt = store.onChange { [weak self] in
            self?.emitChange()
        }
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

    // MARK: - Refresh Data

    func refreshPostStats(postID: Int) {
        ActionDispatcher.dispatch(PeriodAction.refreshPostStats(postID: postID))
    }

}

// MARK: - Private Extension

private extension PostStatsViewModel {

    // MARK: - Create Table Rows

    func titleTableRow() -> ImmuTableRow {
        return PostStatsTitleRow(postTitle: postTitle ?? NSLocalizedString("(No Title)", comment: "Empty Post Title"),
                                 postURL: postURL,
                                 postStatsDelegate: postStatsDelegate)
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
