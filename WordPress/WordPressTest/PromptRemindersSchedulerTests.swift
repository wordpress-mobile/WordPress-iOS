import XCTest
import OHHTTPStubs
import CoreData

@testable import WordPress

class PromptRemindersSchedulerTests: XCTestCase {
    typealias Schedule = BloggingRemindersScheduler.Schedule
    typealias Weekday = BloggingRemindersScheduler.Weekday

    private let timeout: TimeInterval = 1
    private let currentDate = ISO8601DateFormatter().date(from: "2022-05-20T09:30:00+00:00")! // Friday
    private static var gmtTimeZone = TimeZone(secondsFromGMT: 0)!

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var siteID: Int {
        blog.dotComID!.intValue
    }

    private var contextManager: ContextManager!
    private var serviceFactory: BloggingPromptsServiceFactory!
    private var notificationScheduler: MockNotificationScheduler!
    private var pushAuthorizer: MockPushNotificationAuthorizer!
    private var blog: Blog!
    private var accountService: AccountService!
    private var scheduler: PromptRemindersScheduler!
    private var localStore: MockLocalFileStore!
    private var dateProvider: MockCurrentDateProvider!

    override func setUp() {
        contextManager = ContextManager.forTesting()
        serviceFactory = BloggingPromptsServiceFactory(contextManager: contextManager)
        notificationScheduler = MockNotificationScheduler()
        pushAuthorizer = MockPushNotificationAuthorizer()
        dateProvider = MockCurrentDateProvider(currentDate)
        blog = makeBlog()
        accountService = makeAccountService()
        localStore = MockLocalFileStore()
        scheduler = PromptRemindersScheduler(bloggingPromptsServiceFactory: serviceFactory,
                                             notificationScheduler: notificationScheduler,
                                             pushAuthorizer: pushAuthorizer,
                                             localStore: localStore,
                                             currentDateProvider: dateProvider)
        NSTimeZone.default = TimeZone(secondsFromGMT: 0)!

        stubFetchPromptsResponse()

        super.setUp()
    }

    override func tearDown() {
        contextManager = nil
        serviceFactory = nil
        notificationScheduler = nil
        pushAuthorizer = nil
        dateProvider = nil
        localStore = nil
        blog = nil
        accountService = nil
        scheduler = nil
        NSTimeZone.default = NSTimeZone.system

        HTTPStubs.removeAllStubs()

        super.tearDown()
    }

    // MARK: - Tests

    func test_schedule_addsNotificationRequestsCorrectly() {
        let schedule = Schedule.weekdays([.saturday])
        let expectedHour = 10
        let expectedMinute = 0

        struct Expected {
            let body: String?
            let dateComponents: DateComponents
            let userInfo: [AnyHashable: AnyHashable]

            static func values(for siteID: Int, hour: Int, minute: Int) -> [Self] {
                return [
                    // prompt notifications
                    Expected(body: "Prompt text 1",
                             dateComponents: .init(year: 2022, month: 5, day: 21, hour: hour, minute: minute),
                             userInfo: [
                                BloggingPrompt.NotificationKeys.promptID: 101,
                                BloggingPrompt.NotificationKeys.siteID: siteID
                             ]),
                    Expected(body: "Prompt text 8",
                             dateComponents: .init(year: 2022, month: 5, day: 28, hour: hour, minute: minute),
                             userInfo: [
                                BloggingPrompt.NotificationKeys.promptID: 108,
                                BloggingPrompt.NotificationKeys.siteID: siteID
                             ]),

                    // static notifications
                    Expected(body: .staticNotificationContent,
                             dateComponents: .init(year: 2022, month: 6, day: 4, hour: hour, minute: minute),
                             userInfo: [
                                BloggingPrompt.NotificationKeys.siteID: siteID
                             ]),
                    Expected(body: .staticNotificationContent,
                             dateComponents: .init(year: 2022, month: 6, day: 11, hour: hour, minute: minute),
                             userInfo: [
                                BloggingPrompt.NotificationKeys.siteID: siteID
                             ]),
                ]
            }
        }

        let expectedValues = Expected.values(for: siteID, hour: expectedHour, minute: expectedMinute)
        let expectation = expectation(description: "Notification scheduling should succeed")
        scheduler.schedule(schedule, for: blog, time: makeTime(hour: expectedHour, minute: expectedMinute)) { result in
            guard case .success = result else {
                XCTFail("Expected a success result, but got error: \(result)")
                expectation.fulfill()
                return
            }

            XCTAssertEqual(self.notificationScheduler.requests.count, expectedValues.count)

            // verify mappings to notification request.
            for (index, request) in self.notificationScheduler.requests.enumerated() {
                let value = expectedValues[index]
                XCTAssertEqual(request.content.body, value.body)
                XCTAssertNotNil(request.trigger)
                XCTAssertNotNil(request.trigger as? UNCalendarNotificationTrigger)

                // verify user info
                let userInfo = request.content.userInfo as! [AnyHashable: AnyHashable]
                XCTAssertEqual(userInfo, value.userInfo)

                let trigger = request.trigger as! UNCalendarNotificationTrigger
                XCTAssertEqual(trigger.dateComponents.year, value.dateComponents.year)
                XCTAssertEqual(trigger.dateComponents.month, value.dateComponents.month)
                XCTAssertEqual(trigger.dateComponents.day, value.dateComponents.day)
                XCTAssertEqual(trigger.dateComponents.hour, value.dateComponents.hour)
                XCTAssertEqual(trigger.dateComponents.minute, value.dateComponents.minute)
            }

            // verify that notification receipts are stored.
            XCTAssertNotNil(self.localStore.storedReceipts)
            let receipts = self.localStore.receipts(for: self.siteID)!
            XCTAssertFalse(receipts.isEmpty)
            XCTAssertEqual(receipts.count, expectedValues.count)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_schedule_givenEmptySchedule_doesNothing() {
        let schedule = Schedule.none

        let expectation = expectation(description: "Notification scheduling should succeed")
        scheduler.schedule(schedule, for: blog) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                expectation.fulfill()
                return
            }

            XCTAssertTrue(self.notificationScheduler.requests.isEmpty)

            // Passing `.none` should NOT trigger push notification authorization!
            XCTAssertFalse(self.pushAuthorizer.triggered)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_schedule_givenTodayIsIncluded_withReminderTimeAfterCurrentTime_includesTodayInSchedule() {
        let schedule = scheduleForToday

        let expectation = expectation(description: "Notification scheduling should succeed")
        scheduler.schedule(schedule, for: blog) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                expectation.fulfill()
                return
            }

            XCTAssertEqual(self.notificationScheduler.requests.count, 5) // 3 prompt + 2 static notifications
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_schedule_givenTodayIsIncluded_withReminderTimeMinutesAfterCurrentTime_excludesTodayFromSchedule() {
        let schedule = scheduleForToday
        let expectedHour = 9
        let expectedMinute = 35
        let dateForTime = makeTime(hour: expectedHour, minute: expectedMinute)

        let expectation = expectation(description: "Notification scheduling should succeed")
        scheduler.schedule(schedule, for: blog, time: dateForTime) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                expectation.fulfill()
                return
            }

            XCTAssertEqual(self.notificationScheduler.requests.count, 5) // 3 prompt + 2 static notifications

            // verify that the reminder time is set correctly.
            let request = self.notificationScheduler.requests.first!
            let trigger = request.trigger! as! UNCalendarNotificationTrigger
            XCTAssertEqual(trigger.dateComponents.hour, expectedHour)
            XCTAssertEqual(trigger.dateComponents.minute, expectedMinute)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_schedule_givenTodayIsIncluded_withReminderTimeBeforeCurrentTime_excludesTodayFromSchedule() {
        let schedule = scheduleForToday
        let expectedHour = 8
        let expectedMinute = 30
        let dateForTime = makeTime(hour: expectedHour, minute: expectedMinute)

        let expectation = expectation(description: "Notification scheduling should succeed")
        scheduler.schedule(schedule, for: blog, time: dateForTime) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                expectation.fulfill()
                return
            }

            // today should be skipped because the reminder is set to 8:30 while current time is 9:00.
            XCTAssertEqual(self.notificationScheduler.requests.count, 4) // 2 prompt + 2 static notifications

            // verify that the reminder time is set correctly.
            let request = self.notificationScheduler.requests.first!
            let trigger = request.trigger! as! UNCalendarNotificationTrigger
            XCTAssertEqual(trigger.dateComponents.hour, expectedHour)
            XCTAssertEqual(trigger.dateComponents.minute, expectedMinute)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_schedule_givenTodayIsIncluded_withReminderTimeMinutesBeforeCurrentTime_excludesTodayFromSchedule() {
        let schedule = scheduleForToday
        let expectedHour = 9
        let expectedMinute = 20
        let dateForTime = makeTime(hour: expectedHour, minute: expectedMinute)

        let expectation = expectation(description: "Notification scheduling should succeed")
        scheduler.schedule(schedule, for: blog, time: dateForTime) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                expectation.fulfill()
                return
            }

            XCTAssertEqual(self.notificationScheduler.requests.count, 4) // 2 prompt + 2 static notifications
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_schedule_givenDeniedPushAuthorization_shouldReturnFailure() {
        let schedule = scheduleForToday
        pushAuthorizer.shouldAuthorize = false

        let expectation = expectation(description: "Notification scheduling should succeed")
        scheduler.schedule(schedule, for: blog) { result in
            guard case .failure(let error) = result else {
                XCTFail("Expected a failure result")
                expectation.fulfill()
                return
            }

            guard case BloggingRemindersScheduler.Error.needsPermissionForPushNotifications = error else {
                XCTFail("Expected BloggingRemindersScheduler.Error.needsPermissionForPushNotifications, instead got: \(String(describing: error))")
                return
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    // MARK: Unscheduling

    func test_unschedule_shouldRemoveNotificationRequestsAndReceipts() {
        let schedule = scheduleForToday

        // schedule the notifications beforehand.
        let expectation = expectation(description: "Notification scheduling should succeed")
        scheduler.schedule(schedule, for: blog) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                expectation.fulfill()
                return
            }

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)

        // there should be notification requests and receipts stored.
        XCTAssertFalse(notificationScheduler.requests.isEmpty)
        XCTAssertNotNil(localStore.receipts(for: siteID))
        XCTAssertFalse(localStore.receipts(for: siteID)!.isEmpty)

        // perform the unschedule operation.
        scheduler.unschedule(for: blog)

        // the requests and receipts should be wiped.
        XCTAssertFalse(notificationScheduler.removedIdentifiers.isEmpty)
        XCTAssertNil(localStore.receipts(for: siteID))
    }

    func test_unschedule_shouldNotImpactReceiptsFromOtherSites() {
        // Arrange
        let schedule = scheduleForToday
        let controlBlog = makeBlog()
        let controlSiteID = controlBlog.dotComID!.intValue

        // first, schedule reminders in the control blog.
        let expect = expectation(description: "Notification scheduling should succeed")
        scheduler.schedule(schedule, for: controlBlog) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                expect.fulfill()
                return
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)

        // store the notification requests from the control blog.
        let controlRequestIDs = notificationScheduler.requests.map { $0.identifier }

        // schedule reminders in the default blog.
        let secondExpect = expectation(description: "Notification scheduling for second blog should succeed")
        scheduler.schedule(schedule, for: blog) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                secondExpect.fulfill()
                return
            }
            secondExpect.fulfill()
        }
        wait(for: [secondExpect], timeout: timeout)

        // Act
        // unschedule notifications for the first blog.
        scheduler.unschedule(for: controlBlog)

        // Assert
        // verify that notification requests and receipts from the control blog is removed.
        XCTAssertNil(localStore.receipts(for: controlSiteID))
        XCTAssertTrue(controlRequestIDs.reduce(into: true) { partialResult, requestID in
            partialResult = partialResult && notificationScheduler.removedIdentifiers.contains(requestID)
        })

        // verify that the notification requests and receipts from the default blog is retained.
        XCTAssertNotNil(localStore.receipts(for: siteID))
        XCTAssertFalse(notificationScheduler.requests.isEmpty)
    }
}

// MARK: - Private Helpers

private extension PromptRemindersSchedulerTests {

    var mainContext: NSManagedObjectContext {
        contextManager.mainContext
    }

    var scheduleForToday: Schedule {
        // the mocked current date is Friday.
        .weekdays([.friday])
    }

    func stubFetchPromptsResponse() {
        stub(condition: isMethodGET()) { _ in
            return .init(jsonObject: self.makeDynamicPromptObjects(), statusCode: 200, headers: ["Content-Type": "application/json"])
        }
    }

    func makeDynamicPromptObjects(count: Int = 15) -> Any {
        var objects = [Any]()
        let currentDate = dateProvider.date()

        for i in 0..<count {
            let date = Calendar.current.date(byAdding: .day, value: i, to: currentDate)!
            objects.append([
                "id": 100 + i,
                "text": "Prompt text \(i)",
                "attribution": "",
                "date": Self.dateFormatter.string(from: date),
                "answered": false,
                "answered_users_count": 0,
                "answered_users_sample": [[String: Any]](),
                "answered_link": "",
                "answered_link_text": "View all responses"
            ] as [String: Any])
        }

        return objects
    }

    func makeBlog() -> Blog {
        return BlogBuilder(mainContext).isHostedAtWPcom().build()
    }

    func makeAccountService() -> AccountService {
        let service = AccountService(coreDataStack: contextManager)
        let accountID = service.createOrUpdateAccount(withUsername: "testuser", authToken: "authtoken")
        let account = try! contextManager.mainContext.existingObject(with: accountID) as! WPAccount
        account.userID = NSNumber(value: 1)
        service.setDefaultWordPressComAccount(account)

        return service
    }

    func makeTime(hour: Int, minute: Int) -> Date? {
        let timeComponents = DateComponents(hour: hour, minute: minute)
        return Calendar.current.date(from: timeComponents)
    }

    class MockNotificationScheduler: NotificationScheduler {
        var requests = [UNNotificationRequest]()
        var removedIdentifiers = [String]()

        func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
            requests.append(request)
            completionHandler?(nil)
        }

        func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
            removedIdentifiers.append(contentsOf: identifiers)
        }
    }

    class MockPushNotificationAuthorizer: PushNotificationAuthorizer {
        var shouldAuthorize = true
        var triggered = false

        func requestAuthorization(completion: @escaping (Bool) -> Void) {
            triggered = true
            completion(shouldAuthorize)
        }
    }

    class MockCurrentDateProvider: CurrentDateProvider {
        var dateToReturn: Date

        init(_ date: Date) {
            dateToReturn = date
        }

        func date() -> Date {
            return dateToReturn
        }
    }

    class MockLocalFileStore: LocalFileStore {
        enum Errors: Error {
            case dataNotFound
        }

        var fileShouldExist = true
        var savedData: Data? = try? PropertyListEncoder().encode([Int: [String]]())
        var saveShouldSucceed = true

        var storedReceipts: [Int: [String]]? {
            guard let savedData = savedData,
                  let dictionary = try? PropertyListDecoder().decode([Int: [String]].self, from: savedData) else {
                return nil
            }

            return dictionary
        }

        func receipts(for siteID: Int) -> [String]? {
            return storedReceipts?[siteID]
        }

        // MARK: LocalFileStore

        func data(from url: URL) throws -> Data {
            guard let someData = savedData else {
                throw Errors.dataNotFound
            }

            return someData
        }

        func fileExists(at url: URL) -> Bool {
            return fileShouldExist
        }

        @discardableResult
        func save(contents: Data, at url: URL) -> Bool {
            savedData = contents

            return saveShouldSucceed
        }

        func containerURL(forAppGroup appGroup: String) -> URL? {
            return nil
        }

        func removeItem(at url: URL) throws {
            // no-op
        }

        func copyItem(at srcURL: URL, to dstURL: URL) throws {
            // no-op
        }
    }
}

private extension String {
    static let staticNotificationContent = NSLocalizedString("Tap to load today's prompt...", comment: "Title for a push notification with fixed content"
                                                                             + " that invites the user to load today's blogging prompt.")
}
