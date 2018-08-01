
import XCTest
@testable import WordPress

class NotificationContentRouterTests: XCTestCase {

    let utility = NotificationUtility()
    var sut: NotificationContentRouter!
    var coordinator: MockContentCoordinator!

    override func setUp() {
        super.setUp()
        utility.setUp()
        coordinator = MockContentCoordinator()
    }

    override func tearDown() {
        utility.tearDown()
        super.tearDown()
    }

    func testFollowNotificationSourceRoutesToStream() {
        let notification = utility.loadFollowerNotification()
        sut = NotificationContentRouter(activity: notification, coordinator: coordinator)
        try! sut.routeToNotificationSource()

        XCTAssertTrue(coordinator.streamWasDisplayed)
    }
}
