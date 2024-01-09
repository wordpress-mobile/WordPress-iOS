import XCTest
@testable import WordPress

final class NotificationsViewControllerTests: XCTestCase {

    private var controller: NotificationsViewController!
    private var contextManager: ContextManager!
    private var utility: NotificationUtility!

    override func setUpWithError() throws {
        contextManager = ContextManager.forTesting()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        utility = NotificationUtility(coreDataStack: contextManager)
        controller = NotificationsViewController.loadFromStoryboard()
    }

    override func tearDownWithError() throws {
        controller = nil
        contextManager = nil
        utility = nil
    }

    func testResetNotificationsWhenAccountChange() throws {
        // Give
        _ = try utility.loadBadgeNotification()

        // When
        postAccountChangeNotification()

        // Then
        XCTAssertEqual(notificationCount, 0)
    }

    func testResetLastSeenTimeWhenAccountChange() throws {
        // Give
        controller.viewModel.lastSeenTime = "testTime"

        // When
        postAccountChangeNotification()

        // Then
        XCTAssertEqual(controller.viewModel.lastSeenTime, nil)
    }

    func testResetApplicationBadgeWhenAccountChange() throws {
        // Give
        let newUnreadCount = 1
        UIApplication.shared.applicationIconBadgeNumber = 0
        ZendeskUtils.unreadNotificationsCount = newUnreadCount

        // When
        postAccountChangeNotification()

        // Then
        XCTAssertEqual(UIApplication.shared.applicationIconBadgeNumber, newUnreadCount)
    }

    func testNeedsReloadResultsWhenAccountChange() throws {
        // Give
        controller.needsReloadResults = false

        // When
        postAccountChangeNotification()

        // Then
        XCTAssertEqual(controller.needsReloadResults, true)
    }

}

private extension NotificationsViewControllerTests {

    enum Constants {
        static let entityName = "Notification"
    }

    var notificationCount: Int? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.entityName)
        return try? contextManager.mainContext.count(for: request)
    }

    func postAccountChangeNotification() {
        NotificationCenter.default.post(name: .WPAccountDefaultWordPressComAccountChanged, object: nil)
    }
}
