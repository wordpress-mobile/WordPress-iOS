import XCTest
@testable import WordPress

final class WidgetsViewModelMapperTests: XCTestCase {
    func testSingleStatViewModel() {
        let views = 649875
        let date = Date()
        let title = "Views"
        let dateRange = "Today"
        let todayStats = makeTodayWidgetStats(views: views)
        let data = makeTodayData(stats: todayStats, date: date)

        let sut = makeSUT(data)
        let viewModel = sut.getLockScreenSingleStatViewModel(
            title: title,
            dateRange: dateRange
        )

        XCTAssertEqual(viewModel.siteName, data.siteName)
        XCTAssertEqual(viewModel.title, title)
        XCTAssertEqual(viewModel.value, views.abbreviatedString())
        XCTAssertEqual(viewModel.dateRange, dateRange)
        XCTAssertEqual(viewModel.updatedTime, date)
    }

    func testTodayViewsStatsURL() {
        let todayStats = makeTodayWidgetStats(views: 649)
        let data = makeTodayData(stats: todayStats, date: Date())

        let sut = makeSUT(data)
        let statsURL = sut.getStatsURL()

        XCTAssertEqual(statsURL?.absoluteString, "https://wordpress.com/stats/day/0?source=widget")
    }
}

extension WidgetsViewModelMapperTests {
    func makeSUT(_ data: HomeWidgetData) -> LockScreenWidgetViewModelMapper {
        LockScreenWidgetViewModelMapper(data: data)
    }

    func makeTodayData(stats: TodayWidgetStats, date: Date) -> HomeWidgetTodayData {
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
