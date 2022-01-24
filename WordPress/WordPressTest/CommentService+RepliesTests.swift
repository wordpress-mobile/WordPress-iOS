import Foundation
import Nimble
import OHHTTPStubs

@testable import WordPress

final class CommentService_RepliesTests: XCTestCase {
    private let commentID: Int = 1
    private let siteID: Int = 2
    private let authorID: Int = 99
    private let timeout: TimeInterval = 2
    private let commentsV2SuccessFilename = "comments-v2-success.json"
    private let emptyArrayFilename = "empty-array.json"

    private var endpoint: String {
        "sites/\(siteID)/comments"
    }

    private var context: NSManagedObjectContext!
    private var commentService: CommentService!
    private var accountService: AccountService!


    override func setUp() {
        super.setUp()

        context = TestContextManager().mainContext
        commentService = CommentService(managedObjectContext: context)
        accountService = makeAccountService()
    }

    override func tearDown() {
        context.reset()
        ContextManager.overrideSharedInstance(nil)
        HTTPStubs.removeAllStubs()

        context = nil
        commentService = nil
        accountService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_getReplies_givenSuccessfulResult_callsSuccessBlock() {
        let expectation = expectation(description: "Fetch latest reply ID should succeed")
        let expectedReplyID = 54 // from comments-v2-success.json
        HTTPStubs.stubRequest(forEndpoint: endpoint, withFileAtPath: stubFilePath(commentsV2SuccessFilename))

        commentService.getLatestReplyID(for: commentID, siteID: siteID, accountService: accountService) { replyID in
            expect(replyID).to(equal(expectedReplyID))
            expectation.fulfill()
        } failure: { _ in
            XCTFail("This block shouldn't get called.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_getReplies_givenEmptyResult_callsSuccessBlock() {
        let expectation = expectation(description: "Fetch latest reply ID should succeed")
        let expectedReplyID = 0
        HTTPStubs.stubRequest(forEndpoint: endpoint, withFileAtPath: stubFilePath(emptyArrayFilename))

        commentService.getLatestReplyID(for: commentID, siteID: siteID, accountService: accountService) { replyID in
            expect(replyID).to(equal(expectedReplyID))
            expectation.fulfill()
        } failure: { _ in
            XCTFail("This block shouldn't get called.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_getReplies_givenFailureResult_callsFailureBlock() {
        let expectation = expectation(description: "Fetch latest reply ID should fail")
        stub(condition: isMethodGET()) { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }

        commentService.getLatestReplyID(for: commentID, siteID: siteID, accountService: accountService) { _ in
            XCTFail("This block shouldn't get called.")
            expectation.fulfill()
        } failure: { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func test_getReplies_addsCommentIdInParameter() {
        let (mockService, mockApi) = makeMockService()
        let parentKey = CommentServiceRemoteREST.RequestKeys.parent.rawValue

        mockService.getLatestReplyID(for: commentID,
                                     siteID: siteID,
                                     accountService: accountService,
                                     success: { _ in },
                                     failure: { _ in })

        var parameters = [String: Any]()
        expect(mockApi.parametersPassedIn).toNot(beNil())
        expect { parameters = mockApi.parametersPassedIn! as! [String: Any] }.toNot(throwError())
        expect(parameters[parentKey] as? Int).to(equal(commentID))
    }

    func test_getReplies_givenValidAuthorId_shouldAddAuthorIdInParameter() {
        let (mockService, mockApi) = makeMockService()
        let authorKey = CommentServiceRemoteREST.RequestKeys.author.rawValue

        mockService.getLatestReplyID(for: commentID,
                                     siteID: siteID,
                                     accountService: accountService,
                                     success: { _ in },
                                     failure: { _ in })

        var parameters = [String: Any]()
        expect(mockApi.parametersPassedIn).toNot(beNil())
        expect { parameters = mockApi.parametersPassedIn! as! [String: Any] }.toNot(throwError())
        expect(parameters[authorKey] as? Int).to(equal(authorID))
    }
}

// MARK: - Test Helpers

private extension CommentService_RepliesTests {
    // returns a mock service that never calls the success or failure block.
    // primarily used for testing the passed in parameters – see MockWordPressComRestApi
    func makeMockService() -> (CommentService, MockWordPressComRestApi) {
        let mockApi = MockWordPressComRestApi()
        let mockFactory = CommentServiceRemoteFactoryMock(restApi: mockApi)
        return (.init(managedObjectContext: context, commentServiceRemoteFactory: mockFactory), mockApi)
    }

    func makeAccountService() -> AccountService {
        let service = AccountService(managedObjectContext: context)
        let account = service.createOrUpdateAccount(withUsername: "testuser", authToken: "authtoken")
        account.userID = NSNumber(value: authorID)
        service.setDefaultWordPressComAccount(account)

        return service
    }

    func stubFilePath(_ filename: String) -> String {
        return OHPathForFile(filename, type(of: self))!
    }
}

private class CommentServiceRemoteFactoryMock: CommentServiceRemoteFactory {
    var restApi: WordPressComRestApi

    init(restApi: WordPressComRestApi) {
        self.restApi = restApi
    }

    override func restRemote(siteID: NSNumber, api: WordPressComRestApi) -> CommentServiceRemoteREST {
        return CommentServiceRemoteREST(wordPressComRestApi: restApi, siteID: siteID)
    }
}
