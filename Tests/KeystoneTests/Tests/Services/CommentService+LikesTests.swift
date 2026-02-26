import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable import WordPress
@testable import WordPressData

final class CommentService_LikesTests: CoreDataTestCase {

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    // MARK: - Tests

    func test_likeComment_givenSuccessfulAPICall_updateLikesCount() {
        let post = ReaderPost(context: mainContext)
        post.siteID = 1
        post.postID = 2
        let comment = Comment(context: mainContext)
        comment.commentID = 3
        comment.post = post
        contextManager.saveContextAndWait(mainContext)

        let commentService = CommentService(coreDataStack: contextManager)

        // Add a successful HTTP API call stub
        stub(condition: isPath("/rest/v1.1/sites/1/comments/3/likes/new")) { _ in
            HTTPStubsResponse(
                jsonObject: [String: Any](),
                statusCode: 200,
                headers: nil
            )
        }

        // Call the toggle like function and wait for it to complete
        let exp = expectation(description: "Toggle like should complete")
        commentService.toggleLikeStatus(for: comment, siteID: 1) {
            exp.fulfill()
        } failure: { error in
            XCTFail("Unexpected error: \(String(describing: error))")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)

        // The comment's like status should be changed
        XCTAssertTrue(comment.isLiked)
        XCTAssertEqual(comment.likeCount, 1)
    }

    func test_likeComment_givenFailureAPICall_callsFailureBlock() {
        let post = ReaderPost(context: mainContext)
        post.siteID = 1
        post.postID = 2
        let comment = Comment(context: mainContext)
        comment.commentID = 3
        comment.post = post
        contextManager.saveContextAndWait(mainContext)

        let commentService = CommentService(coreDataStack: contextManager)

        // Add an HTTP API call stub that returns 400 response
        stub(condition: isPath("/rest/v1.1/sites/1/comments/3/likes/new")) { _ in
            HTTPStubsResponse(
                jsonObject: [String: Any](),
                statusCode: 400,
                headers: nil
            )
        }

        // Call the toggle like function and wait for it to complete
        let exp = expectation(description: "Toggle like should complete")
        commentService.toggleLikeStatus(for: comment, siteID: 1) {
            XCTFail("The failure block should be called instaled")
            exp.fulfill()
        } failure: { error in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)

        // The comment's like status should remain unchanged
        XCTAssertFalse(comment.isLiked)
        XCTAssertEqual(comment.likeCount, 0)
    }

    func test_unlikeComment_givenSuccessfulAPICall_updateLikesCount() {
        let post = ReaderPost(context: mainContext)
        post.siteID = 1
        post.postID = 2
        let comment = Comment(context: mainContext)
        comment.commentID = 3
        comment.post = post
        comment.isLiked = true
        comment.likeCount = 2
        contextManager.saveContextAndWait(mainContext)

        let commentService = CommentService(coreDataStack: contextManager)

        // Add a successful HTTP API call stub
        stub(condition: isPath("/rest/v1.1/sites/1/comments/3/likes/mine/delete")) { _ in
            HTTPStubsResponse(
                jsonObject: [String: Any](),
                statusCode: 200,
                headers: nil
            )
        }

        // Call the toggle like function and wait for it to complete
        let exp = expectation(description: "Toggle unlike should complete")
        commentService.toggleLikeStatus(for: comment, siteID: 1) {
            exp.fulfill()
        } failure: { error in
            XCTFail("Unexpected error: \(String(describing: error))")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)

        // The comment's like status should be changed
        XCTAssertFalse(comment.isLiked)
        XCTAssertEqual(comment.likeCount, 1)
    }

    func test_unlikeComment_givenFailureAPICall_callsFailureBlock() {
        let post = ReaderPost(context: mainContext)
        post.siteID = 1
        post.postID = 2
        let comment = Comment(context: mainContext)
        comment.commentID = 3
        comment.post = post
        comment.isLiked = true
        comment.likeCount = 2
        contextManager.saveContextAndWait(mainContext)

        let commentService = CommentService(coreDataStack: contextManager)

        // Add an HTTP API call stub that returns 400 response
        stub(condition: isPath("/rest/v1.1/sites/1/comments/3/likes/mine/delete")) { _ in
            HTTPStubsResponse(
                jsonObject: [String: Any](),
                statusCode: 400,
                headers: nil
            )
        }

        // Call the toggle like function and wait for it to complete
        let exp = expectation(description: "Toggle unlike should complete")
        commentService.toggleLikeStatus(for: comment, siteID: 1) {
            XCTFail("The failure block should be called instaled")
            exp.fulfill()
        } failure: { error in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)

        // The comment's like status should remain unchanged
        XCTAssertTrue(comment.isLiked)
        XCTAssertEqual(comment.likeCount, 2)
    }
}
