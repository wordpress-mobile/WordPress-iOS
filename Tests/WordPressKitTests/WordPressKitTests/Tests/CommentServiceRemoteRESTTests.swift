import Foundation
import XCTest

@testable import WordPressKit

final class CommentServiceRemoteRESTTests: RemoteTestCase, RESTTestable {
    private let fetchCommentsSuccessFilename = "site-comments-success.json"
    private let fetchCommentSuccessFilename = "site-comment-success.json"
    private let siteId = 0
    private let commentId = 1
    private var remote: CommentServiceRemoteREST!

    private var siteCommentsEndpoint: String {
        return "sites/\(siteId)/comments"
    }

    private var siteCommentEndpoint: String {
        return "sites/\(siteId)/comments/\(commentId)"
    }

    override func setUp() {
        super.setUp()
        remote = CommentServiceRemoteREST(wordPressComRestApi: getRestApi(), siteID: NSNumber(value: siteId))
    }

    override func tearDown() {
        remote = nil
        super.tearDown()
    }

    // MARK: Tests

    func testGetCommentsSucceeds() {
        let expect = expectation(description: "Fetching site comments should succeed")

        stubRemoteResponse(siteCommentsEndpoint,
                           filename: fetchCommentsSuccessFilename,
                           contentType: .ApplicationJSON)

        remote.getCommentsWithMaximumCount(1,
                                           success: { comments in

            guard let comment = comments?.first as? RemoteComment else {
                XCTFail("Failed to retrieve mock site comment")
                return
            }

            XCTAssertEqual(comment.authorID, NSNumber(value: 12345))
            XCTAssertEqual(comment.author, "Comment Author")
            XCTAssertEqual(comment.authorEmail, "author@email.com")
            XCTAssertEqual(comment.authorUrl, "author URL")
            XCTAssertEqual(comment.authorIP, "000.0.00.000")
            XCTAssertEqual(comment.date, NSDate.with(wordPressComJSONString: "2021-08-04T07:58:49+00:00"))
            XCTAssertEqual(comment.link, "comment URL")
            XCTAssertEqual(comment.parentID, nil)
            XCTAssertEqual(comment.postID, NSNumber(value: 1))
            XCTAssertEqual(comment.postTitle, "Post title")
            XCTAssertEqual(comment.status, "approve")
            XCTAssertEqual(comment.type, "comment")
            XCTAssertEqual(comment.isLiked, false)
            XCTAssertEqual(comment.likeCount, NSNumber(value: 0))
            XCTAssertEqual(comment.canModerate, true)
            XCTAssertEqual(comment.content, "I am comment content")
            XCTAssertEqual(comment.rawContent, "I am comment raw content")
            XCTAssertEqual(comments?.count, 1)
            expect.fulfill()
           }, failure: { _ in
            XCTFail("This callback shouldn't get called")
           })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetSingleCommentSucceeds() {
        let expect = expectation(description: "Fetching a single site comment should succeed")

        stubRemoteResponse(siteCommentEndpoint,
                           filename: fetchCommentSuccessFilename,
                           contentType: .ApplicationJSON)

        remote.getCommentWithID(NSNumber(value: commentId),
                                success: { comment in

            guard let comment = comment else {
                XCTFail("Failed to retrieve mock site comment")
                return
            }

            XCTAssertEqual(comment.authorID, NSNumber(value: 12345))
            XCTAssertEqual(comment.author, "Comment Author")
            XCTAssertEqual(comment.authorEmail, "author@email.com")
            XCTAssertEqual(comment.authorUrl, "author URL")
            XCTAssertEqual(comment.authorIP, "000.0.00.000")
            XCTAssertEqual(comment.date, NSDate.with(wordPressComJSONString: "2021-08-04T07:58:49+00:00"))
            XCTAssertEqual(comment.link, "comment URL")
            XCTAssertEqual(comment.parentID, nil)
            XCTAssertEqual(comment.postID, NSNumber(value: 1))
            XCTAssertEqual(comment.postTitle, "Post title")
            XCTAssertEqual(comment.status, "approve")
            XCTAssertEqual(comment.type, "comment")
            XCTAssertEqual(comment.isLiked, false)
            XCTAssertEqual(comment.likeCount, NSNumber(value: 0))
            XCTAssertEqual(comment.canModerate, true)
            XCTAssertEqual(comment.content, "I am comment content")
            XCTAssertEqual(comment.rawContent, "I am comment raw content")
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
