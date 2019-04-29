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

    private lazy var fullDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate(StatsPeriodUnit.day.dateFormatTemplate)
        return df
    }()

    private lazy var weekDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate(StatsPeriodUnit.week.dateFormatTemplate)
        return df
    }()

    private lazy var monthFormatter: DateFormatter = {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("MMM")
        return df
    }()

    private struct Constants {
        static let maxRowsToDisplay = 6
        static let noTitle = NSLocalizedString("(No Title)", comment: "Empty Post Title")
        static let unknown = NSLocalizedString("Unknown", comment: "Displayed when date cannot be determined.")
        static let weekFormat = NSLocalizedString("%@ - %@, %@", comment: "Post Stats label for week date range. Ex: Mar 25 - Mar 31, 2019")
        static let recentWeeks = NSLocalizedString("Recent Weeks", comment: "Post Stats recent weeks header.")
        static let views = NSLocalizedString("Views", comment: "Label for number of views.")
        static let period = NSLocalizedString("Period", comment: "Label for date periods.")
        static let monthsAndYears = NSLocalizedString("Months and Years", comment: "Post Stats months and years header.")
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
        tableRows.append(contentsOf: yearsTableRows())
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

    func yearsTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()

        tableRows.append(CellHeaderRow(title: Constants.monthsAndYears))
        tableRows.append(TopTotalsPostStatsRow(itemSubtitle: Constants.period,
                                               dataSubtitle: Constants.views,
                                               dataRows: yearsDataRows(),
                                               limitRowsDisplayed: true,
                                               postStatsDelegate: postStatsDelegate))

        return tableRows
    }

    func yearsDataRows() -> [StatsTotalRowData] {

        guard let monthlyBreakdown = postStats?.monthlyBreakdown,
            let maxYear = (monthlyBreakdown.max(by: { $0.date.year! < $1.date.year! }))?.date.year else {
                return []
        }

        let minYear = maxYear - Constants.maxRowsToDisplay
        var yearRows = [StatsTotalRowData]()

        // Create Year rows in descending order
        for year in (minYear...maxYear).reversed() {
            // Get months for year, in descending order
            let months = (monthlyBreakdown.filter({ $0.date.year == year })).sorted(by: { $0.date.month! > $1.date.month! })
            // Sum months views for the year
            let yearTotalViews = months.map({$0.viewsCount}).reduce(0, +)

            if yearTotalViews > 0 {
                yearRows.append(StatsTotalRowData(name: String(year),
                                                  data: yearTotalViews.abbreviatedString(),
                                                  showDisclosure: true,
                                                  childRows: childRowsForYear(months)))
            }
        }

        return yearRows
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
                              data: $0.totalViewsCount.formatWithCommas(),
                              showDisclosure: true,
                              childRows: childRowsForWeek($0))
        }
    }

    // MARK: - Months & Years Helpers

    func childRowsForYear(_ months: [StatsPostViews]) -> [StatsTotalRowData] {
        return months.map {
            StatsTotalRowData(name: displayMonth(forDate: $0.date),
                              data: $0.viewsCount.abbreviatedString())
        }
    }

    func displayMonth(forDate date: DateComponents) -> String {
        guard let month = calendar.date(from: date) else {
            return ""
        }

        return monthFormatter.string(from: month)
    }

    // MARK: - Recent Weeks Helpers

    func childRowsForWeek(_ week: StatsWeeklyBreakdown) -> [StatsTotalRowData] {
        return week.days.reversed().map {
            StatsTotalRowData(name: displayDay(forDate: $0.date),
                              data: $0.viewsCount.formatWithCommas())
        }
    }

    func displayWeek(startDay: DateComponents, endDay: DateComponents) -> String {
        guard
            let startDate = calendar.date(from: startDay),
            let endDate = calendar.date(from: endDay),
            let year = endDay.year else {
                return ""
        }

        // If there is only one day in the week, display just the single day.
        if startDate == endDate {
            return fullDateFormatter.string(from: startDate)
        }

        // If there are multiple days in the week, show the date range.
        return String.localizedStringWithFormat(Constants.weekFormat,
                                                weekDateFormatter.string(from: startDate),
                                                weekDateFormatter.string(from: endDate),
                                                String(year))
    }

    func displayDay(forDate date: DateComponents) -> String {
        guard let day = calendar.date(from: date) else {
            return ""
        }

        return weekDateFormatter.string(from: day)
    }

}
