import Foundation
import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import WordPressKit

final class CommentServiceRemoteREST_APIv2Tests: RemoteTestCase, RESTTestable {
    private let successFilename = "comments-v2-view-context-success.json"
    private let editContextSuccessFilename = "comments-v2-edit-context-success.json"
    private let emptyResultFilename = "empty-array.json"
    private let siteId = 0
    private let commentId = 1
    private var remote: CommentServiceRemoteREST!
    private var siteCommentsEndpoint: String {
        return "sites/\(siteId)/comments"
    }

    override func setUp() {
        super.setUp()
        remote = CommentServiceRemoteREST(wordPressComRestApi: getRestApi(), siteID: NSNumber(value: siteId))
    }

    override func tearDown() {
        remote = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_getCommentsV2_works() {
        let expect = expectation(description: "Fetching comments should succeed")
        stubRemoteResponse(siteCommentsEndpoint, filename: successFilename, contentType: .ApplicationJSON)

        remote.getCommentsV2(for: siteId) { comments in
            XCTAssertEqual(comments.count, 2)

            let firstComment = comments.first!
            XCTAssertEqual(firstComment.commentID, 2)
            XCTAssertEqual(firstComment.postID, 49)
            XCTAssertEqual(firstComment.parentID, 1)
            XCTAssertEqual(firstComment.authorID, 135)
            XCTAssertEqual(firstComment.authorName, "John Doe")
            XCTAssertEqual(firstComment.authorURL, "https://example.com/john-doe")
            XCTAssertEqual(firstComment.date, NSDate.with(wordPressComJSONString: "2021-07-01T10:50:11+00:00"))
            XCTAssertEqual(firstComment.content, "<p>Some example comment.</p>\n")
            XCTAssertEqual(firstComment.link, "https://example.com/2021/05/25/example-post/comment-page-1/#comment-2")
            XCTAssertEqual(firstComment.status, "approve") // verify that it's converted correctly.
            XCTAssertEqual(firstComment.type, "comment")
            XCTAssertEqual(firstComment.authorAvatarURL, "https://example.com/avatar/sample?s=96&d=identicon&r=g")

            // verify that all the edit-only fields are nil.
            XCTAssertNil(firstComment.authorEmail)
            XCTAssertNil(firstComment.authorIP)
            XCTAssertNil(firstComment.authorUserAgent)
            XCTAssertNil(firstComment.rawContent)

            // only verify that the second comment contains a different value.
            // assignment correctness has been verified through the first comment.
            let secondComment = comments.last!
            XCTAssertEqual(secondComment.commentID, 3)

            expect.fulfill()
        } failure: { error in
            XCTFail("This block shouldn't be called: \(error)")
            expect.fulfill()
        }

        wait(for: [expect], timeout: timeout)
    }

    func test_getCommentsV2_correctlyPassesCustomParameters() throws {
        let requestReceived = expectation(description: "HTTP request is received")
        var request: URLRequest?
        stub(condition: isHost("public-api.wordpress.com")) {
            request = $0
            requestReceived.fulfill()
            return HTTPStubsResponse(error: URLError(.networkConnectionLost))
        }

        let expectedParentId = 4
        let expectedAuthorId = 5
        let expectedContext = "edit"
        let parameters: [CommentServiceRemoteREST.RequestKeys: AnyHashable] = [
            .parent: expectedParentId,
            .author: expectedAuthorId,
            .context: expectedContext
        ]
        remote = CommentServiceRemoteREST(wordPressComRestApi: WordPressComRestApi(), siteID: NSNumber(value: siteId))
        remote.getCommentsV2(for: siteId, parameters: parameters, success: { _ in }, failure: { _ in })
        wait(for: [requestReceived], timeout: 0.3)

        let url = try XCTUnwrap(request?.url)
        let queryItems = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems)
        let params = queryItems.reduce(into: [String: String]()) { result, query in
            result[query.name] = query.value
        }

        XCTAssertNotNil(params[CommentServiceRemoteREST.RequestKeys.parent.rawValue])
        XCTAssertEqual(params[CommentServiceRemoteREST.RequestKeys.parent.rawValue], expectedParentId.description)
        XCTAssertNotNil(params[CommentServiceRemoteREST.RequestKeys.author.rawValue])
        XCTAssertEqual(params[CommentServiceRemoteREST.RequestKeys.author.rawValue], expectedAuthorId.description)
        XCTAssertNotNil(params[CommentServiceRemoteREST.RequestKeys.context.rawValue])
        XCTAssertEqual(params[CommentServiceRemoteREST.RequestKeys.context.rawValue], expectedContext)
    }

    func test_getCommentsV2_givenEditContext_parsesAdditionalFields() {
        let expect = expectation(description: "Fetching comments should succeed")
        stubRemoteResponse(siteCommentsEndpoint, filename: editContextSuccessFilename, contentType: .ApplicationJSON)

        remote.getCommentsV2(for: siteId) { comments in
            XCTAssertEqual(comments.count, 2)

            let firstComment = comments.first!
            XCTAssertEqual(firstComment.authorEmail, "john.doe@example.com")
            XCTAssertEqual(firstComment.authorIP, "192.168.1.1")
            XCTAssertEqual(firstComment.authorUserAgent, "Mozilla/5.0 (iPhone; CPU iPhone OS 14_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 wp-iphone/17.6")
            XCTAssertEqual(firstComment.rawContent, "Some example comment.")

            // only verify that the second comment contains a different value.
            // assignment correctness has been verified through the first comment.
            let secondComment = comments.last!
            XCTAssertEqual(secondComment.authorEmail, "mary.sue@example.com")

            expect.fulfill()
        } failure: { _ in
            XCTFail("This block shouldn't be called")
            expect.fulfill()
        }

        wait(for: [expect], timeout: timeout)
    }

    func test_getReplies_givenEmptyResult_callsSuccessBlock() {
        let expect = expectation(description: "Fetching comments should succeed")

        stubRemoteResponse(siteCommentsEndpoint, filename: emptyResultFilename, contentType: .ApplicationJSON)
        remote.getCommentsV2(for: siteId) { comments in
            XCTAssertTrue(comments.isEmpty)
            expect.fulfill()
        } failure: { _ in
            XCTFail("This callback shouldn't get called")
        }

        wait(for: [expect], timeout: timeout)
    }

    func test_getReplies_givenFailureResult_callsFailureBlock() {
        let expect = expectation(description: "Fetching comments should fail")

        stubRemoteResponse(siteCommentsEndpoint, filename: emptyResultFilename, contentType: .ApplicationJSON, status: 500)
        remote.getCommentsV2(for: siteId) { _ in
            XCTFail("This callback shouldn't get called")
        } failure: { _ in
            expect.fulfill()
        }

        wait(for: [expect], timeout: timeout)
    }
}
