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
            XCTAssertEqual(params.chartBarsUnit, .month)
        default:
            XCTFail("Unexpected query after calling refreshTrafficOverviewData")
        }
    }

    func testTableViewModel_overviewRows_weekPeriod() {
        sut.refreshTrafficOverviewData(withDate: StatsTrafficBarChartMockData.Week.statsSummaryTimeIntervalData.periodEndDate, forPeriod: .week)

        store.timeIntervalsSummaryStatus = .loading
        XCTAssertTrue(firstRow is StatsGhostChartImmutableRow)
        store.timeIntervalsSummary = StatsTrafficBarChartMockData.Week.statsSummaryTimeIntervalData
        store.timeIntervalsSummaryStatus = .success

        let overviewRow = firstRow as! OverviewRow
        XCTAssertNotNil(overviewRow)
        XCTAssertEqual(overviewRow.period, .week)
        XCTAssertEqual(overviewRow.tabsData.map { $0.tabData }, [StatsTrafficBarChartMockData.Week.barChartTabData1, StatsTrafficBarChartMockData.Week.barChartTabData2, StatsTrafficBarChartMockData.Week.barChartTabData3, StatsTrafficBarChartMockData.Week.barChartTabData4].map { $0.tabData })
        let dataSetEntries = (overviewRow.chartData.first?.barChartData.dataSets as? [BarChartDataSet])?.first?.entries
        XCTAssertEqual(dataSetEntries?.count, StatsTrafficBarChartMockData.Week.statsSummaryTimeIntervalData.summaryData.count)
    }

    func testTableViewModel_ovewrviewRows_yearPeriod() {
        sut.refreshTrafficOverviewData(withDate: StatsTrafficBarChartMockData.Year.statsSummaryTimeIntervalData.periodEndDate, forPeriod: .year)

        store.timeIntervalsSummaryStatus = .loading
        XCTAssertTrue(firstRow is StatsGhostChartImmutableRow)
        store.timeIntervalsSummary = StatsTrafficBarChartMockData.Year.statsSummaryTimeIntervalData
        store.timeIntervalsSummaryStatus = .success

        let overviewRow = firstRow as! OverviewRow
        XCTAssertNotNil(overviewRow)
        XCTAssertEqual(overviewRow.period, .year)
        XCTAssertEqual(overviewRow.tabsData.map { $0.tabData }, [StatsTrafficBarChartMockData.Year.barChartTabData1, StatsTrafficBarChartMockData.Year.barChartTabData2, StatsTrafficBarChartMockData.Year.barChartTabData3, StatsTrafficBarChartMockData.Year.barChartTabData4].map { $0.tabData })
        let dataSetEntries = (overviewRow.chartData.first?.barChartData.dataSets as? [BarChartDataSet])?.first?.entries
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
        static let barChartTabData1 = OverviewTabData(
            tabTitle: "Views",
            tabData: 247,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .week
        )

        static let barChartTabData2 = OverviewTabData(
            tabTitle: "Visitors",
            tabData: 10,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .week
        )

        static let barChartTabData3 = OverviewTabData(
            tabTitle: "Likes",
            tabData: 3,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .week
        )

        static let barChartTabData4 = OverviewTabData(
            tabTitle: "Comments",
            tabData: 0,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .week
        )

        static let statsSummaryData = [
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 724550400.0),
                viewsCount: 247,
                visitorsCount: 10,
                likesCount: 3,
                commentsCount: 0
            )
        ]

        static let statsSummaryTimeIntervalData = StatsSummaryTimeIntervalData(
            period: .week,
            unit: .week,
            periodEndDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
            summaryData: statsSummaryData
        )
    }

    struct Year {
        static let barChartTabData1 = OverviewTabData(
            tabTitle: "Views",
            tabData: 676,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .year
        )

        static let barChartTabData2 = OverviewTabData(
            tabTitle: "Visitors",
            tabData: 30,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .year
        )

        static let barChartTabData3 = OverviewTabData(
            tabTitle: "Likes",
            tabData: 26,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .year
        )

        static let barChartTabData4 = OverviewTabData(
            tabTitle: "Comments",
            tabData: 27,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726796800.0),
            period: .year
        )

        static let statsSummaryData = [
            StatsSummaryData(
                period: .year,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 676,
                visitorsCount: 30,
                likesCount: 26,
                commentsCount: 27
            )
        ]

        static let statsSummaryTimeIntervalData = StatsSummaryTimeIntervalData(
            period: .year,
            unit: .year,
            periodEndDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
            summaryData: statsSummaryData
        )
    }
}
