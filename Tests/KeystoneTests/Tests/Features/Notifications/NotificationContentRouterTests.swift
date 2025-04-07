
import XCTest
@testable import WordPress
@testable import WordPressData

class NotificationContentRouterTests: CoreDataTestCase {

    func testFollowNotificationSourceRoutesToStream() throws {
        let utility = NotificationUtility(coreDataStack: contextManager)
        let coordinator = MockContentCoordinator()
        let notification = try utility.loadFollowerNotification()
        let sut = NotificationContentRouter(activity: notification, coordinator: coordinator)
        try! sut.routeToNotificationSource()

        XCTAssertTrue(coordinator.streamWasDisplayed)
    }
}
