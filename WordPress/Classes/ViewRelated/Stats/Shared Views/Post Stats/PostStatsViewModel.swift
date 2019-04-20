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
    private var postStats: StatsPostDetails?

    private lazy var calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .autoupdatingCurrent
        return cal
    }()

    private lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate(Constants.monthFormat)
        return df
    }()

    private struct Constants {
        static let maxRowsToDisplay = 6
        static let monthFormat = "MMM d"
        static let noTitle = NSLocalizedString("(No Title)", comment: "Empty Post Title")
        static let unknown = NSLocalizedString("Unknown", comment: "Displayed when date cannot be determined.")
        static let weekFormat = NSLocalizedString("%@ - %@, %@", comment: "Post Stats label for week date range. Ex: Mar 25 - Mar 31, 2019")
        static let recentWeeks = NSLocalizedString("Recent Weeks", comment: "Post Stats recent weeks header.")
        static let views = NSLocalizedString("Views", comment: "Label for number of views.")
        static let period = NSLocalizedString("Period", comment: "Label for date periods.")
    }

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

        postStats = store.getPostStats()
        var tableRows = [ImmuTableRow]()

        tableRows.append(titleTableRow())
        tableRows.append(contentsOf: overviewTableRows())
        tableRows.append(contentsOf: recentWeeksTableRows())
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
        return PostStatsTitleRow(postTitle: postTitle ?? Constants.noTitle,
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

    func recentWeeksTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()

        tableRows.append(CellHeaderRow(title: Constants.recentWeeks))
        tableRows.append(TopTotalsPostStatsRow(itemSubtitle: Constants.period,
                                               dataSubtitle: Constants.views,
                                               dataRows: recentWeeksDataRows(),
                                               limitRowsDisplayed: false,
                                               postStatsDelegate: postStatsDelegate))

        return tableRows
    }

    func recentWeeksDataRows() -> [StatsTotalRowData] {
        let recentWeeks = postStats?.recentWeeks ?? []

        return recentWeeks.reversed().prefix(Constants.maxRowsToDisplay).map {
            StatsTotalRowData(name: displayWeek(startDay: $0.startDay, endDay: $0.endDay),
                              data: String($0.totalViewsCount),
                              showDisclosure: true,
                              childRows: childRowsForWeek($0))
        }
    }

    // MARK: - Recent Weeks Helpers

    func childRowsForWeek(_ week: StatsWeeklyBreakdown) -> [StatsTotalRowData] {
        return week.days.reversed().map {
            StatsTotalRowData(name: displayDay(forDate: $0.date), data: String($0.viewsCount))
        }
    }

    func displayWeek(startDay: DateComponents, endDay: DateComponents) -> String {
        guard
            let startDate = calendar.date(from: startDay),
            let endDate = calendar.date(from: endDay),
            let year = endDay.year else {
                return ""
        }

        return String.localizedStringWithFormat(Constants.weekFormat,
                                                dateFormatter.string(from: startDate),
                                                dateFormatter.string(from: endDate),
                                                String(year))
    }

    func displayDay(forDate date: DateComponents) -> String {
        guard let day = calendar.date(from: date) else {
            return ""
        }

        return dateFormatter.string(from: day)
    }

}
