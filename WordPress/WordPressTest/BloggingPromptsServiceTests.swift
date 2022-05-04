import XCTest

@testable import WordPress

final class BloggingPromptsServiceTests: XCTestCase {
    private let siteID = 1
    private let timeout: TimeInterval = 2
    private var endpoint: String {
        "sites/\(siteID)/blogging-prompts"
    }

    private var contextManager: ContextManagerMock!
    private var context: NSManagedObjectContext! {
        contextManager.mainContext
    }
    private var remote: BloggingPromptsServiceRemoteMock!
    private var service: BloggingPromptsService!
    private var blog: Blog!
    private var accountService: AccountService!

    override func setUp() {
        super.setUp()

        contextManager = ContextManagerMock()
        remote = BloggingPromptsServiceRemoteMock()
        blog = makeBlog()
        accountService = makeAccountService()
        service = BloggingPromptsService(context: context, remote: remote, blog: blog)
    }

    override func tearDown() {
        contextManager = nil
        remote = nil
        blog = nil
        accountService = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_fetchPrompts_givenSuccessfulResult_callsSuccessBlock() {
        let expectation = expectation(description: "Fetch prompts should succeed")

        service.fetchPrompts { _ in
            // TODO: Add mapping tests once CoreData model is added.
            expectation.fulfill()
        } failure: { _ in
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
        let expectedNumber = 24
        remote.shouldReturnSuccess = false

        // call the fetch just to trigger default parameter assignment. the completion blocks can be ignored.
        service.fetchPrompts(success: { _ in }, failure: { _ in })

        XCTAssertNotNil(remote.passedDateParameter)
        let passedDate = remote.passedDateParameter!
        let differenceInHours = Calendar.autoupdatingCurrent.dateComponents([.hour], from: passedDate, to: Date()).hour!
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
        let service = AccountService(managedObjectContext: context)
        let account = service.createOrUpdateAccount(withUsername: "testuser", authToken: "authtoken")
        account.userID = NSNumber(value: 1)
        service.setDefaultWordPressComAccount(account)

        return service
    }

    func makeBlog() -> Blog {
        return BlogBuilder(context).isHostedAtWPcom().build()
    }
}

class BloggingPromptsServiceRemoteMock: BloggingPromptsServiceRemote {
    var passedSiteID: NSNumber? = nil
    var passedNumberParameter: Int? = nil
    var passedDateParameter: Date? = nil
    var shouldReturnSuccess: Bool = true

    override func fetchPrompts(for siteID: NSNumber,
                               number: Int? = nil,
                               fromDate: Date? = nil,
                               completion: @escaping (Result<[RemoteBloggingPrompt], Error>) -> Void) {
        passedSiteID = siteID
        passedNumberParameter = number
        passedDateParameter = fromDate

        if shouldReturnSuccess {
            completion(.success([]))
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
