import XCTest
@testable import WordPress

class DashboardStatsViewModelTests: XCTestCase {

    func testReturnCorrectDataFromAPIResponse() {
        // Given
        let statsData = BlogDashboardRemoteEntity.BlogDashboardStats(views: 1, visitors: 2, likes: 3, comments: 0)
        let stats = FailableDecodable(value: statsData)
        let apiResponse = BlogDashboardRemoteEntity(posts: nil, todaysStats: stats)
        let viewModel = DashboardStatsViewModel(apiResponse: apiResponse)

        // When & Then
        XCTAssertEqual(viewModel.todaysViews, "1")
        XCTAssertEqual(viewModel.todaysVisitors, "2")
        XCTAssertEqual(viewModel.todaysLikes, "3")
    }

    func testReturnedDataIsFormattedCorrectly() {
        // Given
        let statsData = BlogDashboardRemoteEntity.BlogDashboardStats(views: 10000, visitors: 200000, likes: 3000000, comments: 0)
        let stats = FailableDecodable(value: statsData)
        let apiResponse = BlogDashboardRemoteEntity(posts: nil, todaysStats: stats)
        let viewModel = DashboardStatsViewModel(apiResponse: apiResponse)

        // When & Then
        XCTAssertEqual(viewModel.todaysViews, "10,000")
        XCTAssertEqual(viewModel.todaysVisitors, "200.0K")
        XCTAssertEqual(viewModel.todaysLikes, "3.0M")
    }

    func testReturnZeroIfAPIResponseIsEmpty() {
        // Given
        let statsData = BlogDashboardRemoteEntity.BlogDashboardStats(views: nil, visitors: nil, likes: nil, comments: nil)
        let stats = FailableDecodable(value: statsData)
        let apiResponse = BlogDashboardRemoteEntity(posts: nil, todaysStats: stats)
        let viewModel = DashboardStatsViewModel(apiResponse: apiResponse)

        // When & Then
        XCTAssertEqual(viewModel.todaysViews, "0")
        XCTAssertEqual(viewModel.todaysVisitors, "0")
        XCTAssertEqual(viewModel.todaysLikes, "0")
    }

    func testReturnTrueIfAllTodaysStatsAreZero() {
        // Given
        let statsData = BlogDashboardRemoteEntity.BlogDashboardStats(views: 0, visitors: 0, likes: 0, comments: 0)
        let stats = FailableDecodable(value: statsData)
        let apiResponse = BlogDashboardRemoteEntity(posts: nil, todaysStats: stats)
        let viewModel = DashboardStatsViewModel(apiResponse: apiResponse)

        // When & Then
        XCTAssertEqual(viewModel.shouldDisplayNudge, true)
    }

    func testReturnFalseIfNotAllTodaysStatsAreZero() {
        // Given
        let statsData = BlogDashboardRemoteEntity.BlogDashboardStats(views: 1, visitors: 0, likes: 0, comments: 0)
        let stats = FailableDecodable(value: statsData)
        let apiResponse = BlogDashboardRemoteEntity(posts: nil, todaysStats: stats)
        let viewModel = DashboardStatsViewModel(apiResponse: apiResponse)

        // When & Then
        XCTAssertEqual(viewModel.shouldDisplayNudge, false)
    }

}
