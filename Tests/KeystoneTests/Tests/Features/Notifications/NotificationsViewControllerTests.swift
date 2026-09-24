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

    func testResetApplicationBadgeWhenAccountChange() throws {
        // Give
        let newUnreadCount = 1
        UIApplication.shared.applicationIconBadgeNumber = 0
        ZendeskUtils.unreadNotificationsCount = newUnreadCount

        // When
        postAccountChangeNotification()

        // Then
        // TODO: rework this unit test
        let expectation = self.expectation(description: "setBadgeCount")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            expectation.fulfill()
        }
        wait(for: [expectation])

        XCTAssertEqual(UIApplication.shared.applicationIconBadgeNumber, newUnreadCount)
    }

    @MainActor
    func testSubmitsSeenForNotificationOutsideSelectedFilter() async throws {
        // Given a visible list filtered to comments
        let uuid = "account-A"
        AccountBuilder(contextManager.mainContext).with(uuid: uuid).build()
        let previousDefaultDotComUUID = UserSettings.defaultDotComUUID
        UserSettings.defaultDotComUUID = uuid
        addTeardownBlock { UserSettings.defaultDotComUUID = previousDefaultDotComUUID }

        let serviceTests = NotificationActivityServiceTests()
        let fixture = await serviceTests.started(uuid: uuid)
        controller = NotificationsViewController.loadFromStoryboard()
        controller.activityService = fixture.service

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        addTeardownBlock { window.isHidden = true }

        controller.filterTabBar.setSelectedIndex(2)
        controller.filterTabBar.sendActions(for: .valueChanged)

        // When a like arrives
        _ = try utility.loadLikeNotification()
        contextManager.mainContext.processPendingChanges()
        await serviceTests.settle(fixture)

        // Then
        // The fixture's timestamp, 2015-03-28T00:23:41+00:00, in Unix seconds.
        XCTAssertEqual(fixture.remote.seenTimestamps, [Date(timeIntervalSince1970: 1_427_502_221)])
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
