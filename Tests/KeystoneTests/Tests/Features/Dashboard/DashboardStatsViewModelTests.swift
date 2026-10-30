import XCTest
@testable import WordPress
import WordPressShared

class DashboardStatsViewModelTests: XCTestCase {

    func testReturnCorrectDataFromAPIResponse() {
        // Given
        let statsData = BlogDashboardRemoteEntity.BlogDashboardStats(views: 1, visitors: 2, likes: 3, comments: 0)
        let stats = FailableDecodable(value: statsData)
        let apiResponse = BlogDashboardRemoteEntity(posts: nil, todaysStats: stats)
        let viewModel = DashboardStatsViewModel(apiResponse: apiResponse)

        // When & Then
        XCTAssertEqual(viewModel.todaysViews.text, "1")
        XCTAssertEqual(viewModel.todaysVisitors.text, "2")
        XCTAssertEqual(viewModel.todaysLikes.text, "3")
    }

    func testReturnedDataIsFormattedCorrectly() {
        // Given
        let statsData = BlogDashboardRemoteEntity.BlogDashboardStats(views: 10000, visitors: 200000, likes: 3000000, comments: 0)
        let stats = FailableDecodable(value: statsData)
        let apiResponse = BlogDashboardRemoteEntity(posts: nil, todaysStats: stats)
        let viewModel = DashboardStatsViewModel(apiResponse: apiResponse)

        // When & Then
        XCTAssertEqual(viewModel.todaysViews.text, "10,000")
        XCTAssertEqual(viewModel.todaysVisitors.text, "200.0K")
        XCTAssertEqual(viewModel.todaysLikes.text, "3.0M")
        XCTAssertEqual(viewModel.todaysViews.accessibilityLabel, "10,000")
        XCTAssertEqual(viewModel.todaysVisitors.accessibilityLabel, "200 thousand")
        XCTAssertEqual(viewModel.todaysLikes.accessibilityLabel, "3 million")
    }

    func testReturnZeroIfAPIResponseIsEmpty() {
        // Given
        let statsData = BlogDashboardRemoteEntity.BlogDashboardStats(views: nil, visitors: nil, likes: nil, comments: nil)
        let stats = FailableDecodable(value: statsData)
        let apiResponse = BlogDashboardRemoteEntity(posts: nil, todaysStats: stats)
        let viewModel = DashboardStatsViewModel(apiResponse: apiResponse)

        // When & Then
        XCTAssertEqual(viewModel.todaysViews.text, "0")
        XCTAssertEqual(viewModel.todaysVisitors.text, "0")
        XCTAssertEqual(viewModel.todaysLikes.text, "0")
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
