import XCTest
@testable import WordPress

final class WidgetsViewModelMapperTests: XCTestCase {
    func testSingleStatViewModel() {
        let views = 649875
        let date = Date()
        let title = "Views Today"
        let todayStats = makeTodayWidgetStats(views: views)
        let data = makeTodayData(stats: todayStats, date: date)

        let sut = makeSUT()
        let viewModel = sut.getLockScreenSingleStatViewModel(
            data: data,
            title: title
        )

        XCTAssertEqual(viewModel.siteName, data.siteName)
        XCTAssertEqual(viewModel.title, title)
        XCTAssertEqual(viewModel.value, views.abbreviatedString())
        XCTAssertEqual(viewModel.updatedTime, date)
    }

    func testTodayViewsStatsURL() {
        let todayStats = makeTodayWidgetStats(views: 649)
        let data = makeTodayData(stats: todayStats, date: Date())
        let statsURL = data.statsURL

        XCTAssertEqual(statsURL?.absoluteString, "https://wordpress.com/stats/day/0")
    }

    func testUnconfiguredViewModel() {
        let sut = makeSUT()
        let message = "Test"
        let viewModel = sut.getLockScreenUnconfiguredViewModel(message)

        XCTAssertEqual(viewModel.message, message)
    }
}

extension WidgetsViewModelMapperTests {
    func makeSUT() -> LockScreenWidgetViewModelMapper {
        LockScreenWidgetViewModelMapper()
    }

    func makeTodayData(stats: TodayWidgetStats, date: Date) -> LockScreenStatsWidgetData {
        HomeWidgetTodayData(siteID: 0,
                            siteName: "My WordPress Site",
                            url: "",
                            timeZone: TimeZone.current,
                            date: date,
                            stats: stats)
    }

    func makeTodayWidgetStats(views: Int) -> TodayWidgetStats {
        TodayWidgetStats(views: views,
                         visitors: 572,
                         likes: 16,
                         comments: 8)
    }
}
