import XCTest
@testable import WordPress

class NotificationSchedulerMock: NotificationScheduler {
    typealias AddNotificationMock = (_ request: UNNotificationRequest, _ completionHandler: ((Error?) -> Void)?) -> Void
    typealias RemoveNotificationMock = (_ requestIdentifier: String) -> Void

    let addNotificationMock: AddNotificationMock
    let removeNotificationMock: RemoveNotificationMock

    init(
        addNotificationMock: @escaping AddNotificationMock,
        removeNotificationMock: @escaping RemoveNotificationMock) {

        self.addNotificationMock = addNotificationMock
        self.removeNotificationMock = removeNotificationMock
    }

    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
        addNotificationMock(request, completionHandler)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        for identifier in identifiers {
            removeNotificationMock(identifier)
        }
    }
}

class PushNotificationsAuthorizerMock: PushNotificationAuthorizer {
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}

class BloggingRemindersSchedulerTests: XCTestCase {

    func dataFileURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("testBlogReminders_" + UUID().uuidString + ".plist")
    }

    func testThatScheduleIsEquatable() {
        let scheduleA = BloggingRemindersScheduler.Schedule.weekdays([.monday, .friday, .sunday])
        let scheduleB = BloggingRemindersScheduler.Schedule.weekdays([.sunday, .monday, .friday, ])
        let scheduleC = BloggingRemindersScheduler.Schedule.weekdays([.monday, .sunday])

        XCTAssertEqual(scheduleA, scheduleB)
        XCTAssertNotEqual(scheduleA, scheduleC)
        XCTAssertNotEqual(scheduleB, scheduleC)
    }

    func testSchedulerSavesSchedule() {
        let days = [BloggingRemindersScheduler.Weekday]([.monday, .tuesday, .saturday])
        let schedule = BloggingRemindersScheduler.Schedule.weekdays(days)
        let store: BloggingRemindersStore

        let context = TestContextManager().mainContext
        let blog = BlogBuilder(context).build()

        do {
            store = try BloggingRemindersStore(dataFileURL: dataFileURL())
        } catch {
            XCTFail(error.localizedDescription)
            return
        }

        let notificationCenter = NotificationSchedulerMock { (request, completionHandler) in
            completionHandler?(nil)
        } removeNotificationMock: { identifier in
        }

        let scheduler = BloggingRemindersScheduler(
            store: store,
            notificationCenter: notificationCenter,
            pushNotificationAuthorizer: PushNotificationsAuthorizerMock())

        scheduler.schedule(schedule, for: blog) { _ in
        }

        XCTAssertEqual(scheduler.schedule(for: blog), schedule)
    }

    /// Tests that the scheduler does schedule and cancel local notifications.
    ///
    func testLocalNotificationsSchedulingAndCancelling() {
        let store: BloggingRemindersStore
        let days = [BloggingRemindersScheduler.Weekday]([.monday, .tuesday, .saturday])

        let scheduleExpectation = expectation(description: "The notification is scheduled")
        scheduleExpectation.expectedFulfillmentCount = days.count

        let cancelExpectation = expectation(description: "The notification is cancelled")
        cancelExpectation.expectedFulfillmentCount = days.count

        let context = TestContextManager().mainContext
        let blog = BlogBuilder(context).build()

        do {
            store = try BloggingRemindersStore(dataFileURL: dataFileURL())
        } catch {
            XCTFail(error.localizedDescription)
            return
        }

        let notificationCenter = NotificationSchedulerMock { (request, completionHandler) in
            scheduleExpectation.fulfill()
            completionHandler?(nil)
        } removeNotificationMock: { identifier in
            cancelExpectation.fulfill()
        }

        let scheduler = BloggingRemindersScheduler(
            store: store,
            notificationCenter: notificationCenter,
            pushNotificationAuthorizer: PushNotificationsAuthorizerMock())

        let storeHasRemindersExpectation = expectation(description: "The notifications are in the store")
        let storeIsEmptyExpectation = expectation(description: "The notifications have been cleared from the store")

        scheduler.schedule(.weekdays(days), for: blog) { _ in
            if store.scheduledReminders(for: blog.objectID.uriRepresentation()) != .none {
                storeHasRemindersExpectation.fulfill()
            }
        }

        scheduler.schedule(.none, for: blog) { _ in
            if store.scheduledReminders(for: blog.objectID.uriRepresentation()) == .none {
                storeIsEmptyExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 0.1) { error in
            if let error = error {
                XCTFail(error.localizedDescription)
            }
        }
    }
}
