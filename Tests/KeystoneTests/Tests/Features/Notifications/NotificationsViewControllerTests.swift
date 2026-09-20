import XCTest
import WordPressData
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
        NotificationCenter.default.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
    }
}
