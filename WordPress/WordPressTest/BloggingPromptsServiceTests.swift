import XCTest
import OHHTTPStubs

@testable import WordPress

final class BloggingPromptsServiceTests: CoreDataTestCase {
    private let siteID = 1
    private let timeout: TimeInterval = 2

    private static let utcTimeZone = TimeZone(secondsFromGMT: 0)!
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.timeZone = utcTimeZone

        return formatter
    }()

    private static var calendar: Calendar = {
        .init(identifier: .gregorian)
    }()

    private var api: MockWordPressComRestApi!
    private var remote: BloggingPromptsServiceRemoteMock!
    private var service: BloggingPromptsService!
    private var blog: Blog!
    private var accountService: AccountService!

    override func setUp() {
        super.setUp()

        api = MockWordPressComRestApi()
        remote = BloggingPromptsServiceRemoteMock()
        blog = makeBlog()
        accountService = makeAccountService()
        service = BloggingPromptsService(contextManager: contextManager, api: api, remote: remote, blog: blog)
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()

        remote = nil
        blog = nil
        accountService = nil
        service = nil
        super.tearDown()
    }

    // MARK: - fetchPrompts Tests

    func test_fetchPrompts_givenSuccessfulResult_callsSuccessBlock() {
        // use actual remote object so the request can be intercepted by HTTPStubs.
        service = BloggingPromptsService(contextManager: contextManager, blog: blog)
        stubFetchPromptsResponse()

        let expectation = expectation(description: "Fetch prompts should succeed")
        service.fetchPrompts(from: .init(timeIntervalSince1970: 0)) { prompts in
            XCTAssertEqual(prompts.count, 2)

            // Verify mappings for the first prompt
            let firstPrompt = prompts.first!
            XCTAssertEqual(firstPrompt.promptID, 248)
            XCTAssertEqual(firstPrompt.text, "Tell us about a time when you felt out of place.")
            XCTAssertTrue(firstPrompt.attribution.isEmpty)

            let firstDateComponents = Calendar.current.dateComponents(in: Self.utcTimeZone, from: firstPrompt.date)
            XCTAssertEqual(firstDateComponents.year!, 2021)
            XCTAssertEqual(firstDateComponents.month!, 9)
            XCTAssertEqual(firstDateComponents.day!, 12)

            XCTAssertTrue(firstPrompt.answered)
            XCTAssertEqual(firstPrompt.answerCount, 1)
            XCTAssertEqual(firstPrompt.displayAvatarURLs.count, 1)

            // Verify mappings for the second prompt
            let secondPrompt = prompts.last!
            XCTAssertEqual(secondPrompt.promptID, 239)
            XCTAssertEqual(secondPrompt.text, "Was there a toy or thing you always wanted as a child, during the holidays or on your birthday, but never received? Tell us about it.")
            XCTAssertEqual(secondPrompt.attribution, "dayone")

            let secondDateComponents = Calendar.current.dateComponents(in: Self.utcTimeZone, from: secondPrompt.date)
            XCTAssertEqual(secondDateComponents.year!, 2022)
            XCTAssertEqual(secondDateComponents.month!, 5)
            XCTAssertEqual(secondDateComponents.day!, 3)

            XCTAssertFalse(secondPrompt.answered)
            XCTAssertEqual(secondPrompt.answerCount, 0)
            XCTAssertTrue(secondPrompt.displayAvatarURLs.isEmpty)

            expectation.fulfill()

        } failure: { error in
            XCTFail("This closure shouldn't be called.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_fetchPrompts_shouldExcludePromptsOutsideGivenDate() {
        // this should exclude the second prompt dated 2021-09-12.
        // the remote may return multiple prompts, but there should be a client-side filtering for the prompt dates.
        let dateParam = Self.dateFormatter.date(from: "2022-01-01")

        // use actual remote object so the request can be intercepted by HTTPStubs.
        service = BloggingPromptsService(contextManager: contextManager, blog: blog)
        stubFetchPromptsResponse()

        let expectation = expectation(description: "Fetch prompts should succeed")
        service.fetchPrompts(from: dateParam) { prompts in
            XCTAssertEqual(prompts.count, 1)

            // Ensure that the date returned is more recent than the supplied date parameter.
            let firstPrompt = prompts.first!
            let firstDateComponents = Calendar.current.dateComponents(in: Self.utcTimeZone, from: firstPrompt.date)
            XCTAssertEqual(firstDateComponents.year!, 2022)
            XCTAssertEqual(firstDateComponents.month!, 5)
            XCTAssertEqual(firstDateComponents.day!, 3)

            expectation.fulfill()

        } failure: { error in
            XCTFail("This closure shouldn't be called.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_fetchPrompts_givenFailureResult_callsFailureBlock() {
        let expectation = expectation(description: "Fetch prompts should fail")

        service.fetchPrompts { _ in
            XCTFail("This closure shouldn't be called.")
            expectation.fulfill()
        } failure: { _ in
            expectation.fulfill()
        }

        api.failureBlockPassedIn?(NSError(code: 0, domain: "", description: ""), nil)

        wait(for: [expectation], timeout: timeout)
    }

    func test_fetchPrompts_givenNoParameters_assignsDefaultValue() throws {
        let expectedDifferenceInDays = 10 // 10 days ago.
        let expectedNumber = 25

        // call the fetch just to trigger default parameter assignment. the completion blocks can be ignored.
        service.fetchPrompts(success: { _ in }, failure: { _ in })

        // calculate the difference and ensure that the passed date is 10 days ago.
        let date = try passedDate()
        let differenceInDays = try XCTUnwrap(Self.calendar.dateComponents([.day], from: date, to: Date()).day)
        XCTAssertEqual(differenceInDays, expectedDifferenceInDays)

        // ensure that the passed number parameter is correct.
        let numberParameter = try XCTUnwrap(passedNumber())
        XCTAssertEqual(numberParameter, expectedNumber)
    }

    func test_fetchPrompts_passesTheDateCorrectly() throws {
        // with the v3 implementation, we no longer have access to intercept at the method level.
        // this means, we lose the time information of the passed date.
        // In this case, we can only compare the year, month, and day components.
        let expectedDate = BloggingPromptsServiceRemoteMock.dateFormatter.date(from: "2022-01-02")!
        let expectedDateComponents = Self.calendar.dateComponents(in: Self.utcTimeZone, from: expectedDate)
        let expectedNumber = 10

        // call the fetch just to trigger default parameter assignment. the completion blocks can be ignored.
        service.fetchPrompts(from: expectedDate, number: expectedNumber, success: { _ in }, failure: { _ in })

        // ensure that we compare the date components in UTC timezone to prevent possible day differences.
        // e.g. edge cases such as `2023-01-02 22:00 -0500` or `2023-01-02 05:00 +0700`.
        let date = try passedDate()
        let dateComponents = Self.calendar.dateComponents(in: Self.utcTimeZone, from: date)
        let year = try passedParameter("force_year") as? Int
        XCTAssertEqual(year, expectedDateComponents.year)
        XCTAssertEqual(dateComponents.month, expectedDateComponents.month)
        XCTAssertEqual(dateComponents.day, expectedDateComponents.day)

        let numberParameter = try XCTUnwrap(passedNumber())
        XCTAssertEqual(numberParameter, expectedNumber)
    }

    // MARK: - Upsert Tests

    // new prompts should overwrite any
    func test_fetchPrompt_shouldOverwritePromptsWithExistingDates() throws {
        // use actual remote object so the request can be intercepted by HTTPStubs.
        service = BloggingPromptsService(contextManager: contextManager, blog: blog)
        stubFetchPromptsResponse()

        let expectedPromptIDs: Set<Int> = [239, 248]

        // insert existing prompts.
        let date = try XCTUnwrap(Self.dateFormatter.date(from: "2022-05-03"))
        makeBloggingPrompt(siteID: Int32(siteID), date: date)
        contextManager.save(contextManager.mainContext)

        let expectation = expectation(description: "Fetch prompts should succeed")
        service.fetchPrompts(from: .distantPast) { prompts in
            // the existing prompt should have been overwritten.
            XCTAssertEqual(prompts.count, 2)

            let promptIDs = Set(prompts.map { Int($0.promptID) })
            XCTAssertTrue(expectedPromptIDs.elementsEqual(promptIDs))

            expectation.fulfill()

        } failure: { error in
            XCTFail("This closure shouldn't be called.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    // there should only be one prompt per date.
    func test_fetchPrompt_shouldDeleteExcessPromptsWithTheSameDates() throws {
        // use actual remote object so the request can be intercepted by HTTPStubs.
        service = BloggingPromptsService(contextManager: contextManager, blog: blog)
        stubFetchPromptsResponse()

        let expectedPromptIDs: Set<Int> = [239, 248]

        // insert existing prompts.
        let date = try XCTUnwrap(Self.dateFormatter.date(from: "2022-05-03"))
        makeBloggingPrompt(siteID: Int32(siteID), date: date)
        makeBloggingPrompt(siteID: Int32(siteID), date: date)
        makeBloggingPrompt(siteID: Int32(siteID), date: date)
        makeBloggingPrompt(siteID: Int32(siteID), date: date)
        makeBloggingPrompt(siteID: Int32(siteID), date: date)
        contextManager.save(contextManager.mainContext)

        let expectation = expectation(description: "Fetch prompts should succeed")
        service.fetchPrompts(from: .distantPast) { prompts in
            // the existing prompt should have been overwritten.
            XCTAssertEqual(prompts.count, 2)

            let promptIDs = prompts.map { Int($0.promptID) }
            XCTAssertTrue(expectedPromptIDs.elementsEqual(promptIDs))

            expectation.fulfill()

        } failure: { error in
            XCTFail("This closure shouldn't be called.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_fetchPrompt_shouldNotOverwritePromptsFromOtherSites() throws {
        // use actual remote object so the request can be intercepted by HTTPStubs.
        service = BloggingPromptsService(contextManager: contextManager, blog: blog)
        stubFetchPromptsResponse()

        let otherSiteID: Int32 = 2

        // insert existing prompts.
        let date = try XCTUnwrap(Self.dateFormatter.date(from: "2022-05-03"))
        makeBloggingPrompt(siteID: otherSiteID, date: date)
        contextManager.save(contextManager.mainContext)

        let expectation = expectation(description: "Fetch prompts should succeed")
        service.fetchPrompts(from: .distantPast) { _ in
            // the prompt dated 2022-05-03 in siteID=2 shouldn't be overwritten.
            let prompts = self.contextManager.mainContext.allObjects(ofType: BloggingPrompt.self)
            XCTAssertEqual(prompts.count, 3)

            expectation.fulfill()

        } failure: { error in
            XCTFail("This closure shouldn't be called.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    // with the force_year parameter, it's possible for the same month and day to share the same `promptID`.
    // however, the `promptID` property is not unique or marked as primary key so duplicate IDs should be OK.
    func test_fetchPrompt_shouldNotOverwriteExistingPromptFromLastYear() throws {
        // use actual remote object so the request can be intercepted by HTTPStubs.
        service = BloggingPromptsService(contextManager: contextManager, blog: blog)
        stubFetchPromptsResponse()

        let promptID: Int32 = 239 // same promptID as 2022-05-03 from mock data.

        // insert existing prompts.
        let date = try XCTUnwrap(Self.dateFormatter.date(from: "2021-05-03")) // one year before 2022-05-03.
        makeBloggingPrompt(siteID: Int32(siteID), promptID: promptID, date: date)
        contextManager.save(contextManager.mainContext)

        let expectation = expectation(description: "Fetch prompts should succeed")
        service.fetchPrompts(from: .distantPast) { prompts in
            XCTAssertEqual(prompts.count, 3)
            expectation.fulfill()
        } failure: { error in
            XCTFail("This closure shouldn't be called.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }
}


// MARK: - Helpers

private extension BloggingPromptsServiceTests {
    func makeAccountService() -> AccountService {
        let service = AccountService(coreDataStack: contextManager)
        let accountID = service.createOrUpdateAccount(withUsername: "testuser", authToken: "authtoken")
        let account = try! contextManager.mainContext.existingObject(with: accountID) as! WPAccount
        account.userID = NSNumber(value: 1)
        service.setDefaultWordPressComAccount(account)

        return service
    }

    func makeBlog() -> Blog {
        return BlogBuilder(mainContext).isHostedAtWPcom().with(blogID: siteID).build()
    }

    func stubFetchPromptsResponse() {
        stub(condition: isMethodGET()) { _ in
            let stubPath = OHPathForFile("blogging-prompts-fetch-success.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type": "application/json"])
        }
    }

    @discardableResult
    func makeBloggingPrompt(siteID: Int32, promptID: Int32? = nil, date: Date) -> BloggingPrompt {
        let prompt = BloggingPrompt.newObject(in: contextManager.mainContext)!
        prompt.siteID = siteID
        prompt.date = date
        prompt.promptID = promptID ?? NSNumber(value: arc4random_uniform(UInt32.max)).int32Value

        return prompt
    }

    // MARK: Mock WordPressComRestAPI Helper

    func passedParameter(_ key: String) throws -> AnyHashable {
        let passedParameters = try XCTUnwrap(api.parametersPassedIn as? [String: AnyHashable])
        return try XCTUnwrap(passedParameters[key], "Param not found for \(key)")
    }

    func passedNumber() throws -> Int? {
        return try passedParameter("per_page") as? Int
    }

    func passedDate() throws -> Date {
        // assumes that `ignoresYear` parameter is enabled.
        // get the month and day components.
        let dateString = try XCTUnwrap(passedParameter("after") as? String)
        let components = dateString.split(separator: "-").compactMap { $0 }
        XCTAssertEqual(components.count, 2)

        // build a date based on the passed values.
        let forcedYear = try passedParameter("force_year") as? Int
        let month = try XCTUnwrap(Int(components.first ?? ""))
        let day = try XCTUnwrap(Int(components.last ?? ""))

        var dateComponents = Self.calendar.dateComponents(in: Self.utcTimeZone, from: Date())
        dateComponents.year = forcedYear
        dateComponents.month = month
        dateComponents.day = day

        return try XCTUnwrap(Self.calendar.date(from: dateComponents))
    }
}

// Let's keep this mock class in case we want to add additional tests for Blogging Prompt Settings.
class BloggingPromptsServiceRemoteMock: BloggingPromptsServiceRemote {
    var passedSiteID: NSNumber? = nil
    var passedNumberParameter: Int? = nil
    var passedDateParameter: Date? = nil
    var shouldReturnSuccess: Bool = true

    enum Errors: Error {
        case failed
    }

    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter
    }()
}
