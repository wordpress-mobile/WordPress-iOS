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

    private var remote: BloggingPromptsServiceRemoteMock!
    private var service: BloggingPromptsService!
    private var blog: Blog!
    private var accountService: AccountService!

    override func setUp() {
        super.setUp()

        remote = BloggingPromptsServiceRemoteMock()
        blog = makeBlog()
        accountService = makeAccountService()
        service = BloggingPromptsService(contextManager: contextManager, remote: remote, blog: blog)
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()

        remote = nil
        blog = nil
        accountService = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Tests

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
            XCTAssertEqual(firstPrompt.title, "Prompt number 10")
            XCTAssertEqual(firstPrompt.content, "<!-- wp:pullquote -->\n<figure class=\"wp-block-pullquote\"><blockquote><p>Tell us about a time when you felt out of place.</p><cite>(courtesy of plinky.com)</cite></blockquote></figure>\n<!-- /wp:pullquote -->")
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
            XCTAssertEqual(secondPrompt.title, "Prompt number 1")
            XCTAssertEqual(secondPrompt.content, "<!-- wp:pullquote -->\n<figure class=\"wp-block-pullquote\"><blockquote><p>Was there a toy or thing you always wanted as a child, during the holidays or on your birthday, but never received? Tell us about it.</p><cite>(courtesy of plinky.com)</cite></blockquote></figure>\n<!-- /wp:pullquote -->")
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
        remote.shouldReturnSuccess = false

        service.fetchPrompts { _ in
            XCTFail("This closure shouldn't be called.")
            expectation.fulfill()
        } failure: { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_fetchPrompts_givenNoParameters_assignsDefaultValue() {
        let expectedDifferenceInHours = 10 * 24 // 10 days ago.
        let expectedNumber = 25
        remote.shouldReturnSuccess = false

        // call the fetch just to trigger default parameter assignment. the completion blocks can be ignored.
        service.fetchPrompts(success: { _ in }, failure: { _ in })

        XCTAssertNotNil(remote.passedDateParameter)
        let passedDate = remote.passedDateParameter!
        let differenceInHours = Calendar.current.dateComponents([.hour], from: passedDate, to: Date()).hour!
        XCTAssertEqual(differenceInHours, expectedDifferenceInHours)

        XCTAssertNotNil(remote.passedNumberParameter)
        XCTAssertEqual(remote.passedNumberParameter!, expectedNumber)
    }

    func test_fetchPrompts_givenValidParameters_passesThemToRemote() {
        let expectedDate = BloggingPromptsServiceRemoteMock.dateFormatter.date(from: "2022-01-02")!
        let expectedNumber = 10
        remote.shouldReturnSuccess = false

        // call the fetch just to trigger default parameter assignment. the completion blocks can be ignored.
        service.fetchPrompts(from: expectedDate, number: expectedNumber, success: { _ in }, failure: { _ in })

        XCTAssertNotNil(remote.passedDateParameter)
        XCTAssertEqual(remote.passedDateParameter!, expectedDate)

        XCTAssertNotNil(remote.passedNumberParameter)
        XCTAssertEqual(remote.passedNumberParameter!, expectedNumber)
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
        return BlogBuilder(mainContext).isHostedAtWPcom().build()
    }

    func stubFetchPromptsResponse() {
        stub(condition: isMethodGET()) { _ in
            let stubPath = OHPathForFile("blogging-prompts-fetch-success.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type": "application/json"])
        }
    }
}

class BloggingPromptsServiceRemoteMock: BloggingPromptsServiceRemote {
    var passedSiteID: NSNumber? = nil
    var passedNumberParameter: Int? = nil
    var passedDateParameter: Date? = nil
    var shouldReturnSuccess: Bool = true
    var promptsToReturn = [RemoteBloggingPrompt]()

    override func fetchPrompts(for siteID: NSNumber,
                               number: Int? = nil,
                               fromDate: Date? = nil,
                               completion: @escaping (Result<[RemoteBloggingPrompt], Error>) -> Void) {
        passedSiteID = siteID
        passedNumberParameter = number
        passedDateParameter = fromDate

        if shouldReturnSuccess {
            completion(.success(promptsToReturn))
        } else {
            completion(.failure(Errors.failed))
        }
    }

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
