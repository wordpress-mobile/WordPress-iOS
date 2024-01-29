import XCTest
@testable import WordPress

final class NotificationsViewModelTests: CoreDataTestCase {
    let sutUserDefaults = UserDefaults(suiteName: "mock_notifications_view_model")!
    let mediator: NotificationSyncMediatorProtocol = MockNotificationSyncMediator()

    override func tearDown() async throws {
        try await super.tearDown()
        sutUserDefaults.removeObject(
            forKey: NotificationsViewModel.Constants.lastSeenKey
        )
    }

    func testLastSeenChangedUpdatesDefaults() {
        let sut = NotificationsViewModel(
            userDefaults: sutUserDefaults,
            notificationMediator: mediator
        )
        let testString = "Last Week"
        sut.lastSeenChanged(timestamp: testString)

        XCTAssertEqual(sut.lastSeenTime, testString)
        XCTAssertEqual(
            sutUserDefaults.string(
                forKey: NotificationsViewModel.Constants.lastSeenKey
            ),
            testString
        )
    }

    func testLastSeenChangedUpdatesLastSeenTime() {
        let sut = NotificationsViewModel(
            userDefaults: sutUserDefaults,
            notificationMediator: mediator
        )
        let timestamp = "11/12/2023 07:50"
        sut.lastSeenChanged(timestamp: timestamp)
        XCTAssertEqual(sut.lastSeenTime, timestamp)
    }

    func testDidChangeDefaultAccountNullifiesLastSeenTime() {
        let sut = NotificationsViewModel(
            userDefaults: sutUserDefaults,
            notificationMediator: mediator
        )
        let timestamp = "11/12/2023 07:50"
        sut.lastSeenChanged(timestamp: timestamp)
        sut.didChangeDefaultAccount()
        XCTAssertNil(sut.lastSeenTime)
    }

    func testLoadNotificationsReturnsNilWhenIndexIsNegative() {
        let sut = NotificationsViewModel(userDefaults: sutUserDefaults)
        let tempNotification = Notification()
        let result = sut.loadNotification(
            near: tempNotification,
            allNotifications: [tempNotification],
            withIndexDelta: -1
        )

        XCTAssertNil(result)
    }
}

final class MockNotificationSyncMediator: NotificationSyncMediatorProtocol {
    var completion: ((Error?) -> Void)?

    func updateLastSeen(_ timestamp: String, completion: ((Error?) -> Void)?) {
        completion?(nil)
    }
}
