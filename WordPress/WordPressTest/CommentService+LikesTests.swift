import Foundation
import Nimble
import OHHTTPStubs
import XCTest

@testable import WordPress

final class CommentService_LikesTests: CoreDataTestCase {

    private var commentService: CommentService!

    override func setUp() {
        super.setUp()
        commentService = CommentService(coreDataStack: contextManager)
    }

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

        // Add a successful HTTP API call stub
        stub(condition: isPath("/rest/v1.1/sites/1/comments/3/likes/new")) { _ in
            HTTPStubsResponse(
                jsonObject: [String: Any](),
                statusCode: 200,
                headers: nil
            )
        }

        // Call the toggle like function and wait for it to complete
        waitUntil { done in
            self.commentService.toggleLikeStatus(for: comment, siteID: 1) {
                done()
            } failure: { error in
                XCTFail("Unexpected error: \(String(describing: error))")
                done()
            }
        }

        // The comment's like status should be changed
        expect(comment.isLiked).toEventually(beTrue())
        expect(comment.likeCount).toEventually(equal(1))
    }

    func test_likeComment_givenFailureAPICall_callsFailureBlock() {
        let post = ReaderPost(context: mainContext)
        post.siteID = 1
        post.postID = 2
        let comment = Comment(context: mainContext)
        comment.commentID = 3
        comment.post = post
        contextManager.saveContextAndWait(mainContext)

        // Add an HTTP API call stub that returns 400 response
        stub(condition: isPath("/rest/v1.1/sites/1/comments/3/likes/new")) { _ in
            HTTPStubsResponse(
                jsonObject: [String: Any](),
                statusCode: 400,
                headers: nil
            )
        }

        // Call the toggle like function and wait for it to complete
        waitUntil { done in
            self.commentService.toggleLikeStatus(for: comment, siteID: 1) {
                XCTFail("The failure block should be called instaled")
                done()
            } failure: { error in
                done()
            }
        }

        // The comment's like status should remain unchanged
        expect(comment.isLiked).toEventually(beFalse())
        expect(comment.likeCount).toEventually(equal(0))
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

        // Add a successful HTTP API call stub
        stub(condition: isPath("/rest/v1.1/sites/1/comments/3/likes/mine/delete")) { _ in
            HTTPStubsResponse(
                jsonObject: [String: Any](),
                statusCode: 200,
                headers: nil
            )
        }

        // Call the toggle like function and wait for it to complete
        waitUntil { done in
            self.commentService.toggleLikeStatus(for: comment, siteID: 1) {
                done()
            } failure: { error in
                XCTFail("Unexpected error: \(String(describing: error))")
                done()
            }
        }

        // The comment's like status should be changed
        expect(comment.isLiked).toEventually(beFalse())
        expect(comment.likeCount).toEventually(equal(1))
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

        // Add an HTTP API call stub that returns 400 response
        stub(condition: isPath("/rest/v1.1/sites/1/comments/3/likes/mine/delete")) { _ in
            HTTPStubsResponse(
                jsonObject: [String: Any](),
                statusCode: 400,
                headers: nil
            )
        }

        // Call the toggle like function and wait for it to complete
        waitUntil { done in
            self.commentService.toggleLikeStatus(for: comment, siteID: 1) {
                XCTFail("The failure block should be called instaled")
                done()
            } failure: { error in
                done()
            }
        }

        // The comment's like status should remain unchanged
        expect(comment.isLiked).toEventually(beTrue())
        expect(comment.likeCount).toEventually(equal(2))
    }
}
