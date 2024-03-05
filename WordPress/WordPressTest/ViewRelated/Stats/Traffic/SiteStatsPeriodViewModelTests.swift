import XCTest
import WordPressFlux
import DGCharts
@testable import WordPress

final class SiteStatsPeriodViewModelTests: XCTestCase {
    private var sut: SiteStatsPeriodViewModel!
    private var store: StatsPeriodStoreMock!

    private var firstRow: ImmuTableRow {
        let section = sut.tableViewSnapshot().sectionIdentifiers[0]
        let rows = sut.tableViewSnapshot().itemIdentifiers(inSection: section)
        return rows[0].immuTableRow
    }

    override func setUpWithError() throws {
        store = StatsPeriodStoreMock(initialState: .init())
        sut = SiteStatsPeriodViewModel(
            store: store,
            selectedDate: Date(),
            selectedPeriod: .day,
            periodDelegate: SiteStatsPeriodDelegateMock(),
            referrerDelegate: SiteStatsReferrerDelegateMock()
        )
        sut.addListeners()
    }

    override func tearDownWithError() throws {
        store = nil
        sut = nil
    }

    func testChangeObserver() {
        let expectation = XCTestExpectation(description: "Change observer called")
        let receipt: Receipt? = sut.onChange {
            expectation.fulfill()
        }

        store.changeDispatcher.dispatch()

        XCTAssertNotNil(receipt)
        wait(for: [expectation], timeout: 1)
    }

    func testRefreshTrafficOverviewData() {
        XCTAssertTrue(store.activeQueries.isEmpty)

        sut.refreshTrafficOverviewData(withDate: Date(), forPeriod: .day)

        XCTAssertNotNil(store.activeQueries.first)
        switch store.activeQueries[0] {
        case .trafficOverviewData(let params):
            XCTAssertEqual(params.period, .day)
            XCTAssertEqual(params.chartBarsUnit, .day)
        default:
            XCTFail("Unexpected query after calling refreshTrafficOverviewData")
        }

        sut.refreshTrafficOverviewData(withDate: Date(), forPeriod: .month)
        XCTAssertNotNil(store.activeQueries.first)
        switch store.activeQueries[0] {
        case .trafficOverviewData(let params):
            XCTAssertEqual(params.period, .month)
            XCTAssertEqual(params.chartBarsUnit, .week)
        default:
            XCTFail("Unexpected query after calling refreshTrafficOverviewData")
        }
    }

    func testTableViewModel_todayRows() {
        sut.refreshTrafficOverviewData(withDate: Date(), forPeriod: .day)

        store.totalsSummaryStatus = .loading
        XCTAssertTrue(firstRow is StatsGhostTopImmutableRow)

        let statsSummaryData = [
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(),
                viewsCount: 1,
                visitorsCount: 2,
                likesCount: 3,
                commentsCount: 4
            )
        ]
        store.totalsSummary = StatsSummaryTimeIntervalData(period: .day, unit: .day, periodEndDate: Date(), summaryData: statsSummaryData)
        store.totalsSummaryStatus = .success

        let expectedRows: [StatsTwoColumnRowData] = [
            StatsTwoColumnRowData(leftColumnName: "Views", leftColumnData: "1", rightColumnName: "Visitors", rightColumnData: "2"),
            StatsTwoColumnRowData(leftColumnName: "Likes", leftColumnData: "3", rightColumnName: "Comments", rightColumnData: "4")
        ]

        XCTAssertEqual((firstRow as? TwoColumnStatsRow)?.dataRows, expectedRows)
    }

    func testTableViewModel_chartRows_weekPeriod() {
        sut.refreshTrafficOverviewData(withDate: StatsTrafficBarChartMockData.Week.statsSummaryTimeIntervalData.periodEndDate, forPeriod: .week)

        store.timeIntervalsSummaryStatus = .loading
        XCTAssertTrue(firstRow is StatsGhostChartImmutableRow)
        store.timeIntervalsSummary = StatsTrafficBarChartMockData.Week.statsSummaryTimeIntervalData
        store.timeIntervalsSummaryStatus = .success
        store.totalsSummary = StatsTrafficBarChartMockData.Week.totalsData
        store.totalsSummaryStatus = .success

        let trafficRow = firstRow as! StatsTrafficBarChartRow
        XCTAssertNotNil(trafficRow)
        XCTAssertEqual(trafficRow.period, .week)
        XCTAssertEqual(trafficRow.unit, .day)
        XCTAssertEqual(trafficRow.tabsData, [StatsTrafficBarChartMockData.Week.barChartTabData1, StatsTrafficBarChartMockData.Week.barChartTabData2, StatsTrafficBarChartMockData.Week.barChartTabData3, StatsTrafficBarChartMockData.Week.barChartTabData4])
        let dataSetEntries = (trafficRow.chartData.first?.barChartData.dataSets as? [BarChartDataSet])?.first?.entries
        XCTAssertEqual(dataSetEntries?.count, StatsTrafficBarChartMockData.Week.statsSummaryTimeIntervalData.summaryData.count)
    }

    func testTableViewModel_chartRows_yearPeriod() {
        sut.refreshTrafficOverviewData(withDate: StatsTrafficBarChartMockData.Year.statsSummaryTimeIntervalData.periodEndDate, forPeriod: .year)

        store.timeIntervalsSummaryStatus = .loading
        XCTAssertTrue(firstRow is StatsGhostChartImmutableRow)
        store.timeIntervalsSummary = StatsTrafficBarChartMockData.Year.statsSummaryTimeIntervalData
        store.timeIntervalsSummaryStatus = .success
        store.totalsSummary = StatsTrafficBarChartMockData.Year.totalsData
        store.totalsSummaryStatus = .success

        let trafficRow = firstRow as! StatsTrafficBarChartRow
        XCTAssertNotNil(trafficRow)
        XCTAssertEqual(trafficRow.period, .year)
        XCTAssertEqual(trafficRow.unit, .month)
        XCTAssertEqual(trafficRow.tabsData, [StatsTrafficBarChartMockData.Year.barChartTabData1, StatsTrafficBarChartMockData.Year.barChartTabData2, StatsTrafficBarChartMockData.Year.barChartTabData3, StatsTrafficBarChartMockData.Year.barChartTabData4])
        let dataSetEntries = (trafficRow.chartData.first?.barChartData.dataSets as? [BarChartDataSet])?.first?.entries
        XCTAssertEqual(dataSetEntries?.count, StatsTrafficBarChartMockData.Year.statsSummaryTimeIntervalData.summaryData.count)
    }
}

private class SiteStatsReferrerDelegateMock: SiteStatsReferrerDelegate {
    func showReferrerDetails(_ data: StatsTotalRowData) {}
}

private class SiteStatsPeriodDelegateMock: SiteStatsPeriodDelegate {}

private class StatsPeriodStoreMock: StatsPeriodStoreProtocol {
    var isFetchingSummary: Bool = false
    var fetchingOverviewHasFailed: Bool = false
    var timeIntervalsSummaryStatus: WordPress.StoreFetchingStatus = .idle
    var totalsSummaryStatus: WordPress.StoreFetchingStatus = .idle
    var topPostsAndPagesStatus: WordPress.StoreFetchingStatus = .idle
    var topReferrersStatus: WordPress.StoreFetchingStatus = .idle
    var topPublishedStatus: WordPress.StoreFetchingStatus = .idle
    var topClicksStatus: WordPress.StoreFetchingStatus = .idle
    var topAuthorsStatus: WordPress.StoreFetchingStatus = .idle
    var topSearchTermsStatus: WordPress.StoreFetchingStatus = .idle
    var topCountriesStatus: WordPress.StoreFetchingStatus = .idle
    var topVideosStatus: WordPress.StoreFetchingStatus = .idle
    var topFileDownloadsStatus: WordPress.StoreFetchingStatus = .idle
    var containsCachedData: Bool = false
    var totalsSummary: StatsSummaryTimeIntervalData? = nil
    var timeIntervalsSummary: StatsSummaryTimeIntervalData? = nil
    var queries: [PeriodQuery] = []

    func containsCachedData(for type: WordPress.PeriodType) -> Bool {
        return containsCachedData
    }

    func getSummary() -> StatsSummaryTimeIntervalData? {
        return timeIntervalsSummary
    }

    func getTotalsSummary() -> StatsSummaryTimeIntervalData? {
        return totalsSummary
    }

    func getTopReferrers() -> StatsTopReferrersTimeIntervalData? {
        return nil
    }

    func getTopClicks() -> StatsTopClicksTimeIntervalData? {
        return nil
    }

    func getTopAuthors() -> StatsTopAuthorsTimeIntervalData? {
        return nil
    }

    func getTopSearchTerms() -> StatsSearchTermTimeIntervalData? {
        return nil
    }

    func getTopVideos() -> StatsTopVideosTimeIntervalData? {
        return nil
    }

    func getTopCountries() -> StatsTopCountryTimeIntervalData? {
        return nil
    }

    func getTopFileDownloads() -> StatsFileDownloadsTimeIntervalData? {
        return nil
    }

    func getTopPostsAndPages() -> StatsTopPostsTimeIntervalData? {
        return nil
    }

    func getTopPublished() -> StatsPublishedPostsTimeIntervalData? {
        return nil
    }
}

struct StatsTrafficBarChartMockData {
    struct Week {
        static let barChartTabData1 = StatsTrafficBarChartTabData(
            tabTitle: "Views",
            tabData: 143,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .week
        )

        static let barChartTabData2 = StatsTrafficBarChartTabData(
            tabTitle: "Visitors",
            tabData: 17,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .week
        )

        static let barChartTabData3 = StatsTrafficBarChartTabData(
            tabTitle: "Likes",
            tabData: 6,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .week
        )

        static let barChartTabData4 = StatsTrafficBarChartTabData(
            tabTitle: "Comments",
            tabData: 3,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .week
        )

        static let statsSummaryData = [
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 2,
                visitorsCount: 1,
                likesCount: 0,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 0,
                visitorsCount: 0,
                likesCount: 0,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 17,
                visitorsCount: 6,
                likesCount: 0,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 37,
                visitorsCount: 9,
                likesCount: 2,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 23,
                visitorsCount: 5,
                likesCount: 0,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 59,
                visitorsCount: 7,
                likesCount: 3,
                commentsCount: 2
            ),
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 8,
                visitorsCount: 5,
                likesCount: 1,
                commentsCount: 1
            )
        ]

        static let totalsSummaryData = [
            StatsSummaryData(
                period: .week,
                periodStartDate: StatsTrafficBarChartMockData.Week.barChartTabData1.date!,
                viewsCount: StatsTrafficBarChartMockData.Week.barChartTabData1.tabData,
                visitorsCount: StatsTrafficBarChartMockData.Week.barChartTabData2.tabData,
                likesCount: StatsTrafficBarChartMockData.Week.barChartTabData3.tabData,
                commentsCount: StatsTrafficBarChartMockData.Week.barChartTabData4.tabData
            )
        ]

        static let statsSummaryTimeIntervalData = StatsSummaryTimeIntervalData(
            period: .week,
            unit: .day,
            periodEndDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
            summaryData: statsSummaryData
        )

        static let totalsData = StatsSummaryTimeIntervalData(
            period: .week,
            unit: .week,
            periodEndDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
            summaryData: totalsSummaryData
        )
    }

    struct Month {
        static let barChartTabData1 = StatsTrafficBarChartTabData(
            tabTitle: "Views",
            tabData: 1136,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .month
        )

        static let barChartTabData2 = StatsTrafficBarChartTabData(
            tabTitle: "Visitors",
            tabData: 49,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .month
        )

        static let barChartTabData3 = StatsTrafficBarChartTabData(
            tabTitle: "Likes",
            tabData: 52,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .month
        )

        static let barChartTabData4 = StatsTrafficBarChartTabData(
            tabTitle: "Comments",
            tabData: 28,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .month
        )

        static let statsSummaryData = [
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 724550400.0),
                viewsCount: 247,
                visitorsCount: 10,
                likesCount: 3,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 725155200.0),
                viewsCount: 232,
                visitorsCount: 22,
                likesCount: 6,
                commentsCount: 2
            ),
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 670,
                visitorsCount: 28,
                likesCount: 27,
                commentsCount: 11
            ),
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726364800.0),
                viewsCount: 319,
                visitorsCount: 31,
                likesCount: 19,
                commentsCount: 14
            ),
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 147,
                visitorsCount: 18,
                likesCount: 6,
                commentsCount: 3
            )
        ]

        static let totalsSummaryData = [
            StatsSummaryData(
                period: .month,
                periodStartDate: StatsTrafficBarChartMockData.Month.barChartTabData1.date!,
                viewsCount: StatsTrafficBarChartMockData.Month.barChartTabData1.tabData,
                visitorsCount: StatsTrafficBarChartMockData.Month.barChartTabData2.tabData,
                likesCount: StatsTrafficBarChartMockData.Month.barChartTabData3.tabData,
                commentsCount: StatsTrafficBarChartMockData.Month.barChartTabData4.tabData
            )
        ]

        static let statsSummaryTimeIntervalData = StatsSummaryTimeIntervalData(
            period: .month,
            unit: .week,
            periodEndDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
            summaryData: statsSummaryData
        )

        static let totalsData = StatsSummaryTimeIntervalData(
            period: .week,
            unit: .week,
            periodEndDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
            summaryData: totalsSummaryData
        )
    }

    struct Year {
        static let barChartTabData1 = StatsTrafficBarChartTabData(
            tabTitle: "Views",
            tabData: 113326,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .year
        )

        static let barChartTabData2 = StatsTrafficBarChartTabData(
            tabTitle: "Visitors",
            tabData: 43329,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .year
        )

        static let barChartTabData3 = StatsTrafficBarChartTabData(
            tabTitle: "Likes",
            tabData: 5232,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .year
        )

        static let barChartTabData4 = StatsTrafficBarChartTabData(
            tabTitle: "Comments",
            tabData: 2538,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .year
        )

        static let statsSummaryData = [
            StatsSummaryData(
                period: .month,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 676,
                visitorsCount: 30,
                likesCount: 26,
                commentsCount: 27
            ),
            StatsSummaryData(
                period: .month,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 1194,
                visitorsCount: 53,
                likesCount: 44,
                commentsCount: 102
            ),
            StatsSummaryData(
                period: .month,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 1236,
                visitorsCount: 39,
                likesCount: 21,
                commentsCount: 83
            ),
            StatsSummaryData(
                period: .month,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 1577,
                visitorsCount: 54,
                likesCount: 48,
                commentsCount: 80
            ),
            StatsSummaryData(
                period: .month,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 659,
                visitorsCount: 29,
                likesCount: 14,
                commentsCount: 36
            ),
            StatsSummaryData(
                period: .month,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 426,
                visitorsCount: 23,
                likesCount: 17,
                commentsCount: 15
            ),
            StatsSummaryData(
                period: .month,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 510,
                visitorsCount: 30,
                likesCount: 18,
                commentsCount: 18
            ),
            StatsSummaryData(
                period: .month,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 750,
                visitorsCount: 27,
                likesCount: 28,
                commentsCount: 57
            ),
            StatsSummaryData(
                period: .month,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 842,
                visitorsCount: 31,
                likesCount: 29,
                commentsCount: 45
            ),
            StatsSummaryData(
                period: .month,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 616,
                visitorsCount: 24,
                likesCount: 13,
                commentsCount: 22
            ),
            StatsSummaryData(
                period: .month,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 842,
                visitorsCount: 36,
                likesCount: 16,
                commentsCount: 12
            ),
            StatsSummaryData(
                period: .month,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 1136,
                visitorsCount: 49,
                likesCount: 52,
                commentsCount: 28
            )
        ]

        static let totalsSummaryData = [
            StatsSummaryData(
                period: .year,
                periodStartDate: StatsTrafficBarChartMockData.Year.barChartTabData1.date!,
                viewsCount: StatsTrafficBarChartMockData.Year.barChartTabData1.tabData,
                visitorsCount: StatsTrafficBarChartMockData.Year.barChartTabData2.tabData,
                likesCount: StatsTrafficBarChartMockData.Year.barChartTabData3.tabData,
                commentsCount: StatsTrafficBarChartMockData.Year.barChartTabData4.tabData
            )
        ]

        static let statsSummaryTimeIntervalData = StatsSummaryTimeIntervalData(
            period: .year,
            unit: .month,
            periodEndDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
            summaryData: statsSummaryData
        )

        static let totalsData = StatsSummaryTimeIntervalData(
            period: .week,
            unit: .week,
            periodEndDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
            summaryData: totalsSummaryData
        )
    }
}
