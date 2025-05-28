import Foundation
import Nimble
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable import WordPress
@testable import WordPressData

final class CommentService_MorderationTests: CoreDataTestCase {

    private var comment: Comment!

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
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    // MARK: - Tests

    func test_approveComment_givenSuccessfulAPICall_updatesStatus() {
        let commentService = CommentService(coreDataStack: contextManager)

        // Add a successful HTTP API call stub
        stub(condition: isMethodPOST() && isPath("/wp/v2/sites/1/comments/3")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "id": 3,
                    "post": 2,
                    "parent": 0,
                    "author": 0,
                    "author_name": "A WordPress Commenter",
                    "author_email": "hello@example.com",
                    "author_url": "https://wordpress.org/",
                    "author_ip": "",
                    "author_user_agent": "",
                    "date": "2025-05-20T23:38:46",
                    "date_gmt": "2025-05-20T23:38:46",
                    "content": [
                        "rendered": "<p>test comment</p>\n",
                        "raw": "test comment"
                    ],
                    "link": "https://example.com/2025/05/20/hello-world/#comment-1",
                    "status": "approved",
                    "type": "comment",
                    "author_avatar_urls": [
                        "24": "https://secure.gravatar.com/avatar/123?s=24&d=mm&r=g",
                        "48": "https://secure.gravatar.com/avatar/123?s=48&d=mm&r=g",
                        "96": "https://secure.gravatar.com/avatar/123?s=96&d=mm&r=g"
                    ],
                    "meta": []
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }

        // Call the moderation function and wait for it to complete
        waitUntil { done in
            commentService.approve(self.comment) {
                done()
            } failure: { error in
                XCTFail("Unexpected error: \(String(describing: error))")
                done()
            }
        }

        // The comment's status should be changed
        XCTAssertEqual(self.comment.status, CommentStatusType.approved.description)
    }

    func test_unapproveComment_givenSuccessfulAPICall_updatesStatus() {
        let commentService = CommentService(coreDataStack: contextManager)

        // Add a successful HTTP API call stub
        stub(condition: isMethodPOST() && isPath("/wp/v2/sites/1/comments/3")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "id": 3,
                    "post": 2,
                    "parent": 0,
                    "author": 0,
                    "author_name": "A WordPress Commenter",
                    "author_email": "hello@example.com",
                    "author_url": "https://wordpress.org/",
                    "author_ip": "",
                    "author_user_agent": "",
                    "date": "2025-05-20T23:38:46",
                    "date_gmt": "2025-05-20T23:38:46",
                    "content": [
                        "rendered": "<p>test comment</p>\n",
                        "raw": "test comment"
                    ],
                    "link": "https://example.com/2025/05/20/hello-world/#comment-1",
                    "status": "hold",
                    "type": "comment",
                    "author_avatar_urls": [
                        "24": "https://secure.gravatar.com/avatar/123?s=24&d=mm&r=g",
                        "48": "https://secure.gravatar.com/avatar/123?s=48&d=mm&r=g",
                        "96": "https://secure.gravatar.com/avatar/123?s=96&d=mm&r=g"
                    ],
                    "meta": []
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }
        // Call the moderation function and wait for it to complete
        waitUntil { done in
            commentService.unapproveComment(self.comment) {
                done()
            } failure: { error in
                XCTFail("Unexpected error: \(String(describing: error))")
                done()
            }
        }

        // The comment's status should be changed
        XCTAssertEqual(self.comment.status, CommentStatusType.pending.description)
    }

    func test_spamComment_givenSuccessfulAPICall_updatesStatus() {
        let commentService = CommentService(coreDataStack: contextManager)

        // Add a successful HTTP API call stub
        stub(condition: isMethodPOST() && isPath("/wp/v2/sites/1/comments/3")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "id": 3,
                    "post": 2,
                    "parent": 0,
                    "author": 0,
                    "author_name": "A WordPress Commenter",
                    "author_email": "hello@example.com",
                    "author_url": "https://wordpress.org/",
                    "author_ip": "",
                    "author_user_agent": "",
                    "date": "2025-05-20T23:38:46",
                    "date_gmt": "2025-05-20T23:38:46",
                    "content": [
                        "rendered": "<p>test comment</p>\n",
                        "raw": "test comment"
                    ],
                    "link": "https://example.com/2025/05/20/hello-world/#comment-1",
                    "status": "spam",
                    "type": "comment",
                    "author_avatar_urls": [
                        "24": "https://secure.gravatar.com/avatar/123?s=24&d=mm&r=g",
                        "48": "https://secure.gravatar.com/avatar/123?s=48&d=mm&r=g",
                        "96": "https://secure.gravatar.com/avatar/123?s=96&d=mm&r=g"
                    ],
                    "meta": []
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }
        // Call the moderation function and wait for it to complete
        waitUntil { done in
            commentService.spamComment(self.comment) {
                done()
            } failure: { error in
                XCTFail("Unexpected error: \(String(describing: error))")
                done()
            }
        }

        // The comment's status should be changed
        XCTAssertEqual(self.comment.status, CommentStatusType.spam.description)
    }

    func test_trashComment_givenSuccessfulAPICall_updatesStatus() {
        let commentService = CommentService(coreDataStack: contextManager)

        // Add a successful HTTP API call stub
        stub(condition: isMethodPOST() && isPath("/wp/v2/sites/1/comments/3")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "id": 3,
                    "post": 2,
                    "parent": 0,
                    "author": 0,
                    "author_name": "A WordPress Commenter",
                    "author_email": "hello@example.com",
                    "author_url": "https://wordpress.org/",
                    "author_ip": "",
                    "author_user_agent": "",
                    "date": "2025-05-20T23:38:46",
                    "date_gmt": "2025-05-20T23:38:46",
                    "content": [
                        "rendered": "<p>test comment</p>\n",
                        "raw": "test comment"
                    ],
                    "link": "https://example.com/2025/05/20/hello-world/#comment-1",
                    "status": "trash",
                    "type": "comment",
                    "author_avatar_urls": [
                        "24": "https://secure.gravatar.com/avatar/123?s=24&d=mm&r=g",
                        "48": "https://secure.gravatar.com/avatar/123?s=48&d=mm&r=g",
                        "96": "https://secure.gravatar.com/avatar/123?s=96&d=mm&r=g"
                    ],
                    "meta": []
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }
        // Call the moderation function and wait for it to complete
        waitUntil { done in
            commentService.trashComment(self.comment) {
                done()
            } failure: { error in
                XCTFail("Unexpected error: \(String(describing: error))")
                done()
            }
        }

        // The comment's status should be changed
        XCTAssertEqual(self.comment.status, CommentStatusType.unapproved.description)
    }

    func test_deleteComment_givenSuccessfulAPICall_updatesStatus() {
        let commentService = CommentService(coreDataStack: contextManager)

        // Add a successful HTTP API call stub
        stub(condition: isMethodDELETE() && isPath("/wp/v2/sites/1/comments/3")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "deleted": true,
                    "previous": [
                        "id": 3,
                        "post": 2,
                        "parent": 0,
                        "author": 0,
                        "author_name": "A WordPress Commenter",
                        "author_email": "hello@example.com",
                        "author_url": "https://wordpress.org/",
                        "author_ip": "",
                        "author_user_agent": "",
                        "date": "2025-05-20T23:38:46",
                        "date_gmt": "2025-05-20T23:38:46",
                        "content": [
                            "rendered": "<p>test comment</p>\n",
                            "raw": "test comment"
                        ],
                        "link": "https://example.com/2025/05/20/hello-world/#comment-1",
                        "status": "approved",
                        "type": "comment",
                        "author_avatar_urls": [
                            "24": "https://secure.gravatar.com/avatar/123?s=24&d=mm&r=g",
                            "48": "https://secure.gravatar.com/avatar/123?s=48&d=mm&r=g",
                            "96": "https://secure.gravatar.com/avatar/123?s=96&d=mm&r=g"
                        ],
                        "meta": []
                    ]
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }

        // Call the moderation function and wait for it to complete
        waitUntil { done in
            commentService.delete(self.comment) {
                done()
            } failure: { error in
                XCTFail("Unexpected error: \(String(describing: error))")
                done()
            }
        }

        // The local comment should not be changed
        XCTAssertEqual(self.comment.status, CommentStatusType.pending.description)
    }

}
