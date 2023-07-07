import XCTest
import OHHTTPStubs

@testable import WordPress

class ReminderScheduleCoordinatorTests: CoreDataTestCase {

    private let timeout = TimeInterval(1)
    private var flagOverrideStore: FeatureFlagOverrideStore!
    private var accountService: AccountService!
    private var bloggingPromptsServiceFactory: BloggingPromptsServiceFactory!
    private var blog: Blog!
    private var mockBloggingScheduler: MockBloggingRemindersScheduler!
    private var mockPromptScheduler: MockPromptRemindersScheduler!
    private var coordinator: ReminderScheduleCoordinator!

    override func setUp() {
        flagOverrideStore = FeatureFlagOverrideStore()
        blog = makeBlog()
        accountService = makeAccountService()
        bloggingPromptsServiceFactory = BloggingPromptsServiceFactory(contextManager: contextManager)
        mockBloggingScheduler = try! MockBloggingRemindersScheduler()
        mockBloggingScheduler.behavior = behaviorForBloggingScheduler()
        mockPromptScheduler = MockPromptRemindersScheduler()
        mockPromptScheduler.behavior = behaviorForPromptScheduler()
        coordinator = ReminderScheduleCoordinator(
            bloggingRemindersScheduler: mockBloggingScheduler,
            promptRemindersScheduler: mockPromptScheduler,
            bloggingPromptsServiceFactory: bloggingPromptsServiceFactory,
            coreDataStack: contextManager
        )
        super.setUp()
    }

    override func tearDown() {
        flagOverrideStore = nil
        accountService = nil
        bloggingPromptsServiceFactory = nil
        blog = nil
        mockBloggingScheduler = nil
        mockPromptScheduler = nil
        coordinator = nil

        super.tearDown()
    }

    // MARK: - Tests

    // scheduled

    func test_scheduled_withPromptsDisabled_returnsScheduleForBloggingReminders() {
        disableBloggingPrompts()
        let expectedSchedule = behaviorForBloggingScheduler().scheduleToReturn

        let returnedSchedule = coordinator.schedule(for: blog)

        XCTAssertEqual(returnedSchedule, expectedSchedule)
    }

    func test_scheduled_withPromptsEnabled_returnsScheduleForBloggingPrompts() {
        let behavior = behaviorForPromptScheduler()
        let expectedSchedule = behavior.scheduleToReturn
        enableBloggingPrompts(with: behavior)

        let returnedSchedule = coordinator.schedule(for: blog)

        XCTAssertEqual(returnedSchedule, expectedSchedule)
    }

    // scheduledTime

    func test_scheduledTime_withPromptsDisabled_returnsScheduledTimeForBloggingReminders() {
        let (expectedHour, expectedMinute) = behaviorForBloggingScheduler().timeComponents
        disableBloggingPrompts()

        let timeDate = coordinator.scheduledTime(for: blog)
        let components = Calendar.current.dateComponents([.hour, .minute], from: timeDate)

        XCTAssertEqual(components.hour!, expectedHour)
        XCTAssertEqual(components.minute!, expectedMinute)
    }

    func test_scheduledTime_withPromptsEnabled_returnsScheduledTimeForBloggingPrompts() {
        let behavior = behaviorForPromptScheduler()
        let (expectedHour, expectedMinute) = behavior.timeComponents
        enableBloggingPrompts(with: behavior)

        let timeDate = coordinator.scheduledTime(for: blog)
        let components = Calendar.current.dateComponents([.hour, .minute], from: timeDate)

        XCTAssertEqual(components.hour!, expectedHour)
        XCTAssertEqual(components.minute!, expectedMinute)
    }

    // schedule

    func test_schedule_withPromptsDisabled_shouldScheduleBloggingReminders() {
        let behavior = behaviorForBloggingScheduler()
        disableBloggingPrompts()

        let expect = expectation(description: "Scheduling should succeed")
        coordinator.schedule(behavior.scheduleToReturn, for: blog, time: behavior.scheduledTimeToReturn) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                expect.fulfill()
                return
            }

            // scheduling blogging reminders should automatically unschedule pending notifications from blogging prompts.
            XCTAssertEqual(self.mockPromptScheduler.behavior.blogToUnschedule, self.blog)

            // ensure that `schedule` is called on the right scheduler.
            XCTAssertTrue(self.mockBloggingScheduler.behavior.scheduleCalled)

            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    func test_schedule_withPromptsEnabled_shouldSchedulePromptReminders() {
        let behavior = behaviorForPromptScheduler()
        enableBloggingPrompts(with: behavior)

        let expect = expectation(description: "Scheduling should succeed")
        coordinator.schedule(behavior.scheduleToReturn, for: blog, time: behavior.scheduledTimeToReturn) { result in
            guard case .success = result else {
                XCTFail("Expected a success result")
                expect.fulfill()
                return
            }

            // scheduling blogging prompts should automatically unschedule pending notifications from blogging reminders.
            XCTAssertEqual(self.mockBloggingScheduler.behavior.blogToUnschedule, self.blog)

            // ensure that `schedule` is called on the right scheduler.
            XCTAssertTrue(self.mockPromptScheduler.behavior.scheduleCalled)

            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    // unschedule

    func test_unschedule_shouldUnscheduleRemindersFromBoth() {
        coordinator.unschedule(for: blog)

        XCTAssertNotNil(mockPromptScheduler.behavior.blogToUnschedule)
        XCTAssertNotNil(mockBloggingScheduler.behavior.blogToUnschedule)
        XCTAssertEqual(mockPromptScheduler.behavior.blogToUnschedule, mockBloggingScheduler.behavior.blogToUnschedule)
    }
}

// MARK: Helpers

private extension ReminderScheduleCoordinatorTests {

    func disableBloggingPrompts() {
        try! flagOverrideStore.override(FeatureFlag.bloggingPrompts, withValue: false)
    }

    func enableBloggingPrompts(with behavior: MockSchedulerBehavior) {
        try! flagOverrideStore.override(FeatureFlag.bloggingPrompts, withValue: true)
        let (hour, minute) = behavior.timeComponents
        makePromptSettings(enabled: true, schedule: behavior.scheduleToReturn, hour: hour, minute: minute)
    }

    @discardableResult
    func makePromptSettings(enabled: Bool = true, schedule: BloggingRemindersScheduler.Schedule = .none, hour: Int, minute: Int) -> BloggingPromptSettings {
        let settings = NSEntityDescription.insertNewObject(forEntityName: "BloggingPromptSettings",
                                                           into: mainContext) as! WordPress.BloggingPromptSettings
        settings.promptRemindersEnabled = enabled
        settings.siteID = blog.dotComID!.int32Value

        let reminderDays = NSEntityDescription.insertNewObject(forEntityName: "BloggingPromptSettingsReminderDays",
                                                               into: mainContext) as! WordPress.BloggingPromptSettingsReminderDays
        if case .weekdays(let weekdays) = schedule {
            reminderDays.sunday = weekdays.contains(.sunday)
            reminderDays.monday = weekdays.contains(.monday)
            reminderDays.tuesday = weekdays.contains(.tuesday)
            reminderDays.wednesday = weekdays.contains(.wednesday)
            reminderDays.thursday = weekdays.contains(.thursday)
            reminderDays.friday = weekdays.contains(.friday)
            reminderDays.saturday = weekdays.contains(.saturday)
        }
        settings.reminderDays = reminderDays
        settings.reminderTime = String(format: "%02d.%02d", hour, minute)

        return settings
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

        /// NOTE: When the whole suite is run, somehow the defaultWordPress account set here is wiped.
        /// The account is created and stored successfully, but the UUID stored in the user defaults is somehow always nil.
        ///
        /// The strangest thing is, it works just fine when this suite is run exclusively; but only fails when the whole suite is run.
        /// My suspicion is that some part may have wiped the user defaults, resetting the default account to nil.
        ///
        /// Until there's a better solution, setting the account UUID directly here seemed to fix the problem.
        ///
        UserDefaults.standard.set(account.uuid, forKey: "AccountDefaultDotcomUUID")

        return service
    }

    func behaviorForBloggingScheduler() -> MockSchedulerBehavior {
        var behavior = MockSchedulerBehavior()
        behavior.scheduleToReturn = .weekdays([.monday, .tuesday, .friday])
        behavior.scheduledTimeToReturn = Calendar.current.date(from: DateComponents(hour: 15, minute: 30))!
        return behavior
    }

    func behaviorForPromptScheduler() -> MockSchedulerBehavior {
        var behavior = MockSchedulerBehavior()
        behavior.scheduleToReturn = .weekdays([.thursday, .wednesday, .saturday])
        behavior.scheduledTimeToReturn = Calendar.current.date(from: DateComponents(hour: 20, minute: 15))!
        return behavior
    }

    struct MockSchedulerBehavior {
        // states
        var scheduleToReturn: BloggingRemindersScheduler.Schedule = .none
        var scheduledTimeToReturn: Date = Date()

        // schedule
        var scheduleCalled = false
        var scheduleReturnsSuccess = true

        // unschedule
        var blogToUnschedule: Blog? = nil

        enum Errors: Error {
            case intended
        }

        var timeComponents: (Int, Int) {
            let components = Calendar.current.dateComponents([.hour, .minute], from: scheduledTimeToReturn)
            return (components.hour!, components.minute!)
        }
    }

    class MockPromptRemindersScheduler: PromptRemindersScheduler {
        var behavior = MockSchedulerBehavior()

        override func schedule(_ schedule: BloggingRemindersScheduler.Schedule,
                               for blog: Blog,
                               time: Date? = nil,
                               completion: @escaping (Result<Void, Swift.Error>) -> ()) {
            behavior.scheduleCalled = true
            completion(behavior.scheduleReturnsSuccess ? .success(()) : .failure(MockSchedulerBehavior.Errors.intended))
        }

        override func unschedule(for blog: Blog) {
            behavior.blogToUnschedule = blog
        }
    }


    class MockBloggingRemindersScheduler: BloggingRemindersScheduler {
        var behavior = MockSchedulerBehavior()

        override func schedule(for blog: Blog) -> BloggingRemindersScheduler.Schedule {
            return behavior.scheduleToReturn
        }

        override func scheduledTime(for blog: Blog) -> Date {
            return behavior.scheduledTimeToReturn
        }

        override func schedule(_ schedule: BloggingRemindersScheduler.Schedule,
                               for blog: Blog,
                               time: Date? = nil,
                               completion: @escaping (Result<Void, Swift.Error>) -> ()) {
            behavior.scheduleCalled = true
            completion(behavior.scheduleReturnsSuccess ? .success(()) : .failure(MockSchedulerBehavior.Errors.intended))
        }

        override func unschedule(for blog: Blog) {
            behavior.blogToUnschedule = blog
        }
    }
}
