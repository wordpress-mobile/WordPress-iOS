import Foundation
import Nimble
import OHHTTPStubs
import XCTest

@testable import WordPress

final class CommentService_MorderationTests: CoreDataTestCase {

    private var comment: Comment!
    private var commentService: CommentService!

    override func setUp() {
        super.setUp()

        let blog = BlogBuilder(mainContext)
            .withAnAccount(username: "test")
            .with(blogID: 1)
            .build()
        blog.account?.authToken = "token"
        comment = Comment(context: mainContext)
        comment.commentID = 3
        comment.blog = blog
        comment.status = CommentStatusType.pending.description
        contextManager.saveContextAndWait(mainContext)

        commentService = CommentService(coreDataStack: contextManager)
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    // MARK: - Tests

    func test_approveComment_givenSuccessfulAPICall_updatesStatus() {
        // Add a successful HTTP API call stub
        stub(condition: isMethodPOST() && isPath("/rest/v1.1/sites/1/comments/3")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "id": 3,
                    "post": 2,
                    "status": "approved",
                    "type": "comment",
                    "content": "<p>test comment</p>\n",
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }

        // Call the moderation function and wait for it to complete
        waitUntil { done in
            self.commentService.approve(self.comment) {
                done()
            } failure: { error in
                XCTFail("Unexpected error: \(String(describing: error))")
                done()
            }
        }

        // The comment's status should be changed
        expect(self.comment.status).toEventually(equal(CommentStatusType.approved.description))
    }

    func test_unapproveComment_givenSuccessfulAPICall_updatesStatus() {
        // Add a successful HTTP API call stub
        stub(condition: isMethodPOST() && isPath("/rest/v1.1/sites/1/comments/3")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "id": 3,
                    "post": 2,
                    "status": "pending",
                    "type": "comment",
                    "content": "<p>test comment</p>\n",
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }

        // Call the moderation function and wait for it to complete
        waitUntil { done in
            self.commentService.unapproveComment(self.comment) {
                done()
            } failure: { error in
                XCTFail("Unexpected error: \(String(describing: error))")
                done()
            }
        }

        // The comment's status should be changed
        expect(self.comment.status).toEventually(equal(CommentStatusType.pending.description))
    }

    func test_spamComment_givenSuccessfulAPICall_updatesStatus() {
        // Add a successful HTTP API call stub
        stub(condition: isMethodPOST() && isPath("/rest/v1.1/sites/1/comments/3")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "id": 3,
                    "post": 2,
                    "status": "spam",
                    "type": "comment",
                    "content": "<p>test comment</p>\n",
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }

        // Call the moderation function and wait for it to complete
        waitUntil { done in
            self.commentService.spamComment(self.comment) {
                done()
            } failure: { error in
                XCTFail("Unexpected error: \(String(describing: error))")
                done()
            }
        }

        // The comment's status should be changed
        expect(self.comment.status).toEventually(equal(CommentStatusType.spam.description))
    }

    func test_trashComment_givenSuccessfulAPICall_updatesStatus() {
        // Add a successful HTTP API call stub
        stub(condition: isMethodPOST() && isPath("/rest/v1.1/sites/1/comments/3")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "id": 3,
                    "post": 2,
                    "status": "trash",
                    "type": "comment",
                    "content": "<p>test comment</p>\n",
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }

        // Call the moderation function and wait for it to complete
        waitUntil { done in
            self.commentService.trashComment(self.comment) {
                done()
            } failure: { error in
                XCTFail("Unexpected error: \(String(describing: error))")
                done()
            }
        }

        // The comment's status should be changed
        expect(self.comment.status).toEventually(equal(CommentStatusType.unapproved.description))
    }

    func test_deleteComment_givenSuccessfulAPICall_updatesStatus() {
        // Add a successful HTTP API call stub
        stub(condition: isMethodPOST() && isPath("/rest/v1.1/sites/1/comments/3/delete")) { _ in
            HTTPStubsResponse(
                jsonObject: [String: Any](),
                statusCode: 200,
                headers: nil
            )
        }

        // Call the moderation function and wait for it to complete
        waitUntil { done in
            self.commentService.delete(self.comment) {
                done()
            } failure: { error in
                XCTFail("Unexpected error: \(String(describing: error))")
                done()
            }
        }

        // The local comment should not be changed
        expect(self.comment.status).toEventually(equal(CommentStatusType.pending.description))
    }

}
