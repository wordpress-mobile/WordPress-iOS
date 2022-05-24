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
    private static var gmtCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = gmtTimeZone
        return calendar
    }()

    private static var gmtDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = gmtTimeZone
        return formatter
    }()

    private var contextManager: ContextManagerMock!
    private var serviceFactory: BloggingPromptsServiceFactory!
    private var notificationScheduler: MockNotificationScheduler!
    private var pushAuthorizer: MockPushNotificationAuthorizer!
    private var blog: Blog!
    private var accountService: AccountService!
    private var scheduler: PromptRemindersScheduler!
    private var dateProvider: MockCurrentDateProvider!

    override func setUp() {
        contextManager = ContextManagerMock()
        serviceFactory = BloggingPromptsServiceFactory(contextManager: contextManager)
        notificationScheduler = MockNotificationScheduler()
        pushAuthorizer = MockPushNotificationAuthorizer()
        dateProvider = MockCurrentDateProvider(currentDate)
        blog = makeBlog()
        accountService = makeAccountService()
        scheduler = PromptRemindersScheduler(bloggingPromptsServiceFactory: serviceFactory,
                                             notificationScheduler: notificationScheduler,
                                             pushAuthorizer: pushAuthorizer,
                                             currentDateProvider: dateProvider)
        NSTimeZone.default = Self.gmtTimeZone

        stubFetchPromptsResponse()

        super.setUp()
    }

    override func tearDown() {
        contextManager = nil
        serviceFactory = nil
        notificationScheduler = nil
        pushAuthorizer = nil
        dateProvider = nil
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

        struct Expected {
            let body: String
            let dateComponents: DateComponents

            static let values = [
                Expected(
                    body: "Prompt text 1",
                    dateComponents: DateComponents(year: 2022, month: 5, day: 21, hour: 10, minute: 0)
                ),
                Expected(
                    body: "Prompt text 8",
                    dateComponents: DateComponents(year: 2022, month: 5, day: 28, hour: 10, minute: 0)
                )
            ]
        }

        let expectation = expectation(description: "Notification scheduling should succeed")
        scheduler.schedule(schedule, for: blog) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                expectation.fulfill()
                return
            }

            XCTAssertEqual(self.notificationScheduler.requests.count, Expected.values.count)

            // verify mappings to notification request.
            for (index, request) in self.notificationScheduler.requests.enumerated() {
                let value = Expected.values[index]
                XCTAssertEqual(request.content.body, value.body)
                XCTAssertNotNil(request.trigger)
                XCTAssertNotNil(request.trigger as? UNCalendarNotificationTrigger)

                let trigger = request.trigger as! UNCalendarNotificationTrigger
                XCTAssertEqual(trigger.dateComponents.year, value.dateComponents.year)
                XCTAssertEqual(trigger.dateComponents.month, value.dateComponents.month)
                XCTAssertEqual(trigger.dateComponents.day, value.dateComponents.day)
                XCTAssertEqual(trigger.dateComponents.hour, value.dateComponents.hour)
                XCTAssertEqual(trigger.dateComponents.minute, value.dateComponents.minute)
            }

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

            XCTAssertEqual(self.notificationScheduler.requests.count, 3)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_schedule_givenTodayIsIncluded_withReminderTimeMinutesAfterCurrentTime_excludesTodayFromSchedule() {
        let schedule = scheduleForToday
        let expectedHour = 9
        let expectedMinute = 35
        let timeComponents = DateComponents(hour: expectedHour, minute: expectedMinute)
        let dateForTime = Calendar.current.date(from: timeComponents)

        let expectation = expectation(description: "Notification scheduling should succeed")
        scheduler.schedule(schedule, for: blog, time: dateForTime) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                expectation.fulfill()
                return
            }

            XCTAssertEqual(self.notificationScheduler.requests.count, 3)

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
        let timeComponents = DateComponents(hour: expectedHour, minute: expectedMinute)
        let dateForTime = Calendar.current.date(from: timeComponents)

        let expectation = expectation(description: "Notification scheduling should succeed")
        scheduler.schedule(schedule, for: blog, time: dateForTime) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                expectation.fulfill()
                return
            }

            // today should be skipped because the reminder is set to 8:30 while current time is 9:00.
            XCTAssertEqual(self.notificationScheduler.requests.count, 2)

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
        let timeComponents = DateComponents(hour: expectedHour, minute: expectedMinute)
        let dateForTime = Calendar.current.date(from: timeComponents)

        let expectation = expectation(description: "Notification scheduling should succeed")
        scheduler.schedule(schedule, for: blog, time: dateForTime) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                expectation.fulfill()
                return
            }

            XCTAssertEqual(self.notificationScheduler.requests.count, 2)
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

            XCTAssertEqual(error as! PromptRemindersScheduler.Errors, PromptRemindersScheduler.Errors.needsPushAuthorization)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
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
            let date = Self.gmtCalendar.date(byAdding: .day, value: i, to: currentDate)!
            objects.append([
                "id": 100 + i,
                "text": "Prompt text \(i)",
                "title": "Prompt title \(i)",
                "content": "Prompt content \(i)",
                "attribution": "",
                "date": Self.gmtDateFormatter.string(from: date),
                "answered": false,
                "answered_users_count": 0,
                "answered_users_sample": []
            ])
        }

        return ["prompts": objects]
    }

    func makeBlog() -> Blog {
        return BlogBuilder(mainContext).isHostedAtWPcom().build()
    }

    func makeAccountService() -> AccountService {
        let service = AccountService(managedObjectContext: mainContext)
        let account = service.createOrUpdateAccount(withUsername: "testuser", authToken: "authtoken")
        account.userID = NSNumber(value: 1)
        service.setDefaultWordPressComAccount(account)

        return service
    }

    class MockNotificationScheduler: NotificationScheduler {
        var requests = [UNNotificationRequest]()

        func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
            requests.append(request)
            completionHandler?(nil)
        }

        func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
            // no-op
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
}
