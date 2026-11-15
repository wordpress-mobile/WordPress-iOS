import XCTest
@testable import WordPress
@testable import WordPressData

final class NotificationsViewModelTests: CoreDataTestCase {

    func testLoadNotificationsReturnsNilWhenIndexIsNegative() {
        let sut = NotificationsViewModel()
        let tempNotification = Notification()
        let result = sut.loadNotification(
            near: tempNotification,
            allNotifications: [tempNotification],
            withIndexDelta: -1
        )

        XCTAssertNil(result)
    }

    func testLoadNotificationsReturnsNilWhenArrayIsEmpty() {
        let sut = NotificationsViewModel()
        let tempNotification = Notification()
        let result = sut.loadNotification(
            near: tempNotification,
            allNotifications: [],
            withIndexDelta: 0
        )

        XCTAssertNil(result)
    }
}
