import XCTest
@testable import WordPressKit

class ServiceRequestTest: XCTestCase {
    let mockRequest = MockServiceRequest()
    var notificationsRequest: ReaderTopicServiceSubscriptionsRequest!
    var postsEmailRequest: ReaderTopicServiceSubscriptionsRequest!
    var commentsRequest: ReaderTopicServiceSubscriptionsRequest!

    override func setUp() {
        super.setUp()

        notificationsRequest = .notifications(siteId: 0, action: .subscribe)
        postsEmailRequest = .postsEmail(siteId: 0, action: .unsubscribe)
        commentsRequest = .comments(siteId: 0, action: .update)
    }

    func testMockServiceRequest() {
        XCTAssertEqual(mockRequest.path, "localhost/path/")
        XCTAssertEqual(mockRequest.apiVersion, ._1_2)
    }

    func testNotificationsRequest() {
        XCTAssertEqual(notificationsRequest.apiVersion, ._2_0)
        XCTAssertEqual(notificationsRequest.path, "read/sites/0/notification-subscriptions/new/")
    }

    func testPostsEmailRequest() {
        XCTAssertEqual(postsEmailRequest.apiVersion, ._1_2)
        XCTAssertEqual(postsEmailRequest.path, "read/site/0/post_email_subscriptions/delete/")
    }

    func testCommentsRequest() {
        XCTAssertEqual(commentsRequest.apiVersion, ._1_2)
        XCTAssertEqual(commentsRequest.path, "read/site/0/comment_email_subscriptions/update/")
    }
}
