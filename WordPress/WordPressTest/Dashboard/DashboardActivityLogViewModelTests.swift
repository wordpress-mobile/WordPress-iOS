import XCTest
@testable import WordPress

final class DashboardActivityLogViewModelTests: XCTestCase {

    func testReturnMaxThreeItems() {
        // Given
        let activities = try? [
            Activity.mock(id: "1"),
            Activity.mock(id: "2"),
            Activity.mock(id: "3"),
            Activity.mock(id: "4"),
            Activity.mock(id: "5"),
        ]

        let currentActivity = BlogDashboardRemoteEntity.BlogDashboardActivity.CurrentActivity(orderedItems: activities)
        let activityData = BlogDashboardRemoteEntity.BlogDashboardActivity(current: currentActivity)
        let activity = FailableDecodable(value: activityData)
        let apiResponse = BlogDashboardRemoteEntity(activity: activity)
        let viewModel = DashboardActivityLogViewModel(apiResponse: apiResponse)

        // When & Then
        XCTAssertEqual(viewModel.activitiesToDisplay.count, 3)
        XCTAssertEqual(viewModel.activitiesToDisplay[0].activityID, "1")
        XCTAssertEqual(viewModel.activitiesToDisplay[1].activityID, "2")
        XCTAssertEqual(viewModel.activitiesToDisplay[2].activityID, "3")
    }

    func testReturnUniqueItems() {
        // Given
        let activities = try? [
            Activity.mock(id: "1"),
            Activity.mock(id: "1"),
            Activity.mock(id: "1"),
            Activity.mock(id: "2"),
            Activity.mock(id: "2"),
            Activity.mock(id: "3"),
            Activity.mock(id: "4")
        ]

        let currentActivity = BlogDashboardRemoteEntity.BlogDashboardActivity.CurrentActivity(orderedItems: activities)
        let activityData = BlogDashboardRemoteEntity.BlogDashboardActivity(current: currentActivity)
        let activity = FailableDecodable(value: activityData)
        let apiResponse = BlogDashboardRemoteEntity(activity: activity)
        let viewModel = DashboardActivityLogViewModel(apiResponse: apiResponse)

        // When & Then
        XCTAssertEqual(viewModel.activitiesToDisplay.count, 3)
        XCTAssertEqual(viewModel.activitiesToDisplay[0].activityID, "1")
        XCTAssertEqual(viewModel.activitiesToDisplay[1].activityID, "2")
        XCTAssertEqual(viewModel.activitiesToDisplay[2].activityID, "3")
    }
}
