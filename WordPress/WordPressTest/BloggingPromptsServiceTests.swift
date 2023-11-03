import XCTest
import OHHTTPStubs

@testable import WordPress

final class BloggingPromptsServiceTests: CoreDataTestCase {
    private let siteID = 1
    private let timeout: TimeInterval = 2
    private let fetchPromptsResponseFileName = "blogging-prompts-fetch-success"

    private static let utcTimeZone = TimeZone(secondsFromGMT: 0)!

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.timeZone = utcTimeZone
        return formatter
    }()

    private static var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.supportMultipleDateFormats
        return decoder
    }()

    private static var calendar: Calendar = {
        .init(identifier: .gregorian)
    }()

    private var api: MockWordPressComRestApi!
    private var remote: BloggingPromptsServiceRemoteMock!
    private var service: BloggingPromptsService!
    private var blog: Blog!
    private var accountService: AccountService!

    // Prompts data parsed from the stubbed response.
    private lazy var testPrompts: [BloggingPromptRemoteObject] = {
        let bundle = Bundle(for: BloggingPromptsServiceTests.self)
        guard let url = bundle.url(forResource: fetchPromptsResponseFileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let prompts = try? Self.jsonDecoder.decode([BloggingPromptRemoteObject].self, from: data) else {
            return []
        }
        return prompts
    }()

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
        service.fetchPrompts(from: .init(timeIntervalSince1970: 0)) { [testPrompts] prompts in
            XCTAssertEqual(prompts.count, testPrompts.count)

            prompts.forEach { prompt in
                guard let expected = testPrompts.first(where: { $0.promptID == prompt.promptID }) else {
                    XCTFail("Prompt with ID: \(prompt.promptID) not found in the test data.")
                    return
                }

                XCTAssertEqual(prompt.promptID, Int32(expected.promptID))
                XCTAssertEqual(prompt.text, expected.text)
                XCTAssertEqual(prompt.attribution, expected.attribution)
                XCTAssertEqual(prompt.date, expected.date)
                XCTAssertEqual(prompt.answered, expected.answered)
                XCTAssertEqual(prompt.answerCount, Int32(expected.answeredUsersCount))
                XCTAssertEqual(prompt.displayAvatarURLs.count, expected.answeredUserAvatarURLs.count)
            }

            expectation.fulfill()

        } failure: { error in
            XCTFail("This closure shouldn't be called.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_fetchPrompts_shouldExcludePromptsOutsideGivenDate() throws {
        // this should exclude the second prompt dated 2021-09-12.
        // the remote may return multiple prompts, but there should be a client-side filtering for the prompt dates.
        let dateParam = try XCTUnwrap(Self.dateFormatter.date(from: "2022-01-01"))

        // use actual remote object so the request can be intercepted by HTTPStubs.
        service = BloggingPromptsService(contextManager: contextManager, blog: blog)
        stubFetchPromptsResponse()

        let expectation = expectation(description: "Fetch prompts should succeed")
        service.fetchPrompts(from: dateParam) { prompts in
            XCTAssertEqual(prompts.count, 1)
            let prompt = prompts.first!

            // Ensure that the date returned is more recent than the date parameter.
            XCTAssertTrue(dateParam.compare(prompt.date) == .orderedAscending)

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
        let expectedDifferenceInDays = 10
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

    // new prompts should overwrite any existing prompts.
    func test_fetchPrompt_shouldOverwritePromptsWithExistingDates() throws {
        // use actual remote object so the request can be intercepted by HTTPStubs.
        service = BloggingPromptsService(contextManager: contextManager, blog: blog)
        stubFetchPromptsResponse()

        // the expected prompt IDs locally stored in the app after fetching the prompts.
        // these IDs are from blogging-prompts-fetch-success.json.
        let expectedPromptIDs = Set(testPrompts.map(\.promptID))

        // insert existing prompts.
        let date = try XCTUnwrap(Self.dateFormatter.date(from: "2022-05-03"))
        makeBloggingPrompt(siteID: siteID, promptID: 1000, date: date)
        contextManager.save(contextManager.mainContext)

        let expectation = expectation(description: "Fetch prompts should succeed")
        service.fetchPrompts(from: .distantPast) { prompts in
            // the existing prompt should have been overwritten.
            XCTAssertEqual(prompts.count, expectedPromptIDs.count)

            let promptIDs = Set(prompts.map { Int($0.promptID) })
            XCTAssertTrue(promptIDs == expectedPromptIDs)

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

        // the expected prompt IDs locally stored in the app after fetching the prompts.
        let expectedPromptIDs = Set(testPrompts.map(\.promptID))

        // add 5 existing prompts having the same dates before calling `fetchPrompts`.
        let date = try XCTUnwrap(Self.dateFormatter.date(from: "2022-05-03"))
        for existingID in 1...5 {
            makeBloggingPrompt(siteID: siteID, promptID: existingID, date: date)
        }
        contextManager.save(contextManager.mainContext)

        let expectation = expectation(description: "Fetch prompts should succeed")
        service.fetchPrompts(from: .distantPast) { prompts in
            // the existing prompts should be overwritten by the fetched prompts.
            // additionally, any "excess" prompts should be deleted, leaving only one prompt per date.
            XCTAssertEqual(prompts.count, expectedPromptIDs.count)

            let promptIDs = Set(prompts.map { Int($0.promptID) })
            XCTAssertTrue(promptIDs == expectedPromptIDs)

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

        let otherPromptID = 1000
        let otherSiteID = 2

        // the expected prompt IDs locally stored in the app after fetching the prompts.
        // the first two IDs are from blogging-prompts-fetch-success.json.
        let expectedPromptIDs = Set(testPrompts.map(\.promptID) + [otherPromptID])

        // insert existing prompts.
        let date = try XCTUnwrap(Self.dateFormatter.date(from: "2022-05-03"))
        makeBloggingPrompt(siteID: otherSiteID, promptID: otherPromptID, date: date)
        contextManager.save(contextManager.mainContext)

        let expectation = expectation(description: "Fetch prompts should succeed")
        service.fetchPrompts(from: .distantPast) { _ in
            // the prompt dated 2022-05-03 in siteID=2 shouldn't be overwritten.
            let prompts = self.contextManager.mainContext.allObjects(ofType: BloggingPrompt.self)
            XCTAssertEqual(prompts.count, expectedPromptIDs.count)

            let promptIDs = Set(prompts.map { Int($0.promptID) })
            XCTAssertTrue(promptIDs == expectedPromptIDs)

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

        let date = try XCTUnwrap(Self.dateFormatter.date(from: "2021-05-03")) // one year before 2022-05-03.
        let promptID = try XCTUnwrap(testPrompts.first).promptID // same promptID as 2022-05-03 from the test data.

        // insert existing prompts.
        makeBloggingPrompt(siteID: siteID, promptID: promptID, date: date)
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
    func makeBloggingPrompt(siteID: Int, promptID: Int, date: Date) -> BloggingPrompt {
        let prompt = BloggingPrompt.newObject(in: contextManager.mainContext)!
        prompt.siteID = Int32(siteID)
        prompt.promptID = Int32(promptID)
        prompt.date = date

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
