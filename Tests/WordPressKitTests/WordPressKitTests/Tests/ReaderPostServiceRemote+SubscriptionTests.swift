import XCTest

@testable import WordPressKit

class ReaderPostServiceRemoteSubscriptionTests: RemoteTestCase, RESTTestable {

    // MARK: - Constants

    let siteID: Int = 0
    let postID: Int = 0
    let response = [String: AnyObject]()

    let fetchSubscriptionStatusEndpoint = "sites/0/posts/0/subscribers/mine"
    let subscribeToPostEndpoint = "sites/0/posts/0/subscribers/new"
    let unsubscribeFromPostEndpoint = "sites/0/posts/0/subscribers/mine/delete"
    let updatePostSubscriptionEndpoint = "sites/0/posts/0/subscribers/mine/update"

    let fetchSubscriptionStatusSuccessMockFilename = "reader-post-comments-subscription-status-success.json"
    let subscribeToPostSuccessMockFilename = "reader-post-comments-subscribe-success.json"
    let subscribeToPostSuccessFalseMockFilename = "reader-post-comments-subscribe-failure.json"
    let unsubscribeFromPostSuccessMockFilename = "reader-post-comments-unsubscribe-success.json"
    let updatePostSubscriptionSuccessMockFilename = "reader-post-comments-update-notification-success.json"

    // MARK: - Properties

    var readerPostServiceRemote: ReaderPostServiceRemote!

    override func setUp() {
        super.setUp()
        readerPostServiceRemote = ReaderPostServiceRemote(wordPressComRestApi: getRestApi())
    }

    func testReturnSubscriptionStatus() {
        stubRemoteResponse(fetchSubscriptionStatusEndpoint,
                           filename: fetchSubscriptionStatusSuccessMockFilename,
                           contentType: .ApplicationJSON)

        let expect = expectation(description: "Check for subscription status")
        readerPostServiceRemote.fetchSubscriptionStatus(for: postID, from: siteID, success: { (success) in
            XCTAssertTrue(success, "Success should be true")
            expect.fulfill()
        }) { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testSubscribeToCommentsInPost() {
        stubRemoteResponse(subscribeToPostEndpoint,
                           filename: subscribeToPostSuccessMockFilename,
                           contentType: .ApplicationJSON)

        let expect = expectation(description: "Subscribe to comments for a post")
        readerPostServiceRemote.subscribeToPost(with: postID, for: siteID, success: { (success) in
            XCTAssertTrue(success, "Success should be true")
            expect.fulfill()
        }) { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Test that the attempt to subscribe to comments in a post returns `success: false`
    /// while "Block emails" is enabled on https://wordpress.com/me/notifications/subscriptions
    ///
    func testSubscribeToCommentsInPostSuccessFalse() {
        stubRemoteResponse(subscribeToPostEndpoint,
                           filename: subscribeToPostSuccessFalseMockFilename,
                           contentType: .ApplicationJSON)

        let expect = expectation(description: "Subscribe to comments for a post")
        readerPostServiceRemote.subscribeToPost(with: postID, for: siteID, success: { (successfullySubscribed) in
            XCTAssertFalse(successfullySubscribed, "Success response should be false")
            expect.fulfill()
        }) { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Test that the attempt to unsubscribe to comments in a post allows a user to successfully unsubscribe
    /// whether "Block emails" is enabled on https://wordpress.com/me/notifications/subscriptions or not.
    ///
    func testUnsubscribeFromCommentsInPost() {
        stubRemoteResponse(unsubscribeFromPostEndpoint,
                           filename: unsubscribeFromPostSuccessMockFilename,
                           contentType: .ApplicationJSON)

        let expect = expectation(description: "Unsubscribe from comments for a post")
        readerPostServiceRemote.unsubscribeFromPost(with: postID, for: siteID, success: { (success) in
            XCTAssertTrue(success, "Success should be true")
            expect.fulfill()
        }) { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func test_updateNotificationSettings_givenSuccessCase_callsSuccessBlock() {
        stubRemoteResponse(updatePostSubscriptionEndpoint,
                           filename: updatePostSubscriptionSuccessMockFilename,
                           contentType: .ApplicationJSON)

        let receiveNotifications = true
        let expect = expectation(description: "Update notification settings for post subscription")
        readerPostServiceRemote.updateNotificationSettingsForPost(with: postID,
                                                                  siteID: siteID,
                                                                  receiveNotifications: receiveNotifications,
                                                                  success: {
            // the boolean result should match the receiveNotifications property passed in the params.
            expect.fulfill()
        },
                                                                  failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        wait(for: [expect], timeout: timeout)
    }

    func test_updateNotificationSettings_givenResponseMismatch_callsFailureBlock() {
        stubRemoteResponse(updatePostSubscriptionEndpoint,
                           filename: updatePostSubscriptionSuccessMockFilename,
                           contentType: .ApplicationJSON)

        // expected for the request to enter the failure block since the response data returned does not
        // match the `false` value passed in the request parameter.
        let expect = expectation(description: "Update notification settings for post subscription")
        readerPostServiceRemote.updateNotificationSettingsForPost(with: postID,
                                                                  siteID: siteID,
                                                                  receiveNotifications: false,
                                                                  success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        },
                                                                  failure: { _ in
            expect.fulfill()
        })

        wait(for: [expect], timeout: timeout)
    }

    func test_updateNotificationSettings_givenNetworkFailure_callsFailureBlock() {
        stubRemoteResponse(updatePostSubscriptionEndpoint, data: Data(), contentType: .NoContentType, status: 500)

        let expect = expectation(description: "Update notification settings for post subscription")
        readerPostServiceRemote.updateNotificationSettingsForPost(with: postID,
                                                                  siteID: siteID,
                                                                  receiveNotifications: true,
                                                                  success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        },
                                                                  failure: { _ in
            expect.fulfill()
        })

        wait(for: [expect], timeout: timeout)
    }
}
