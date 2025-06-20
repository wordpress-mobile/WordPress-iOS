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

extension Activity {
    static func mock(id: String = "1", isRewindable: Bool = false) throws -> Activity {
        let dictionary = [
            "activity_id": id,
            "summary": "",
            "is_rewindable": isRewindable,
            "rewind_id": "1",
            "content": ["text": ""],
            "published": "2020-11-09T13:16:43.701+00:00"
        ] as [String: AnyObject]
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        return try JSONDecoder().decode(Activity.self, from: data)
    }
}
