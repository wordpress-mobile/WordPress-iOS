//
//  ServiceRequestTest.swift
//  WordPressKitTests
//
//  Created by Daniele Bogo on 17/04/2018.
//  Copyright © 2018 Automattic Inc. All rights reserved.
//

import XCTest
@testable import WordPressKit


class ServiceRequestTest: XCTestCase {
    var mockRequest: MockServiceRequest!
    var notificationsRequest: ReaderTopicServiceSubscriptionsRequest!
    var postsEmailRequest: ReaderTopicServiceSubscriptionsRequest!
    var commentsRequest: ReaderTopicServiceSubscriptionsRequest!

    
    override func setUp() {
        super.setUp()

        mockRequest = MockServiceRequest()
        notificationsRequest = ReaderTopicServiceSubscriptionsRequest.notifications(siteId: NSNumber(value: 0), action: .subscribe)
        postsEmailRequest = ReaderTopicServiceSubscriptionsRequest.postsEmail(siteId: NSNumber(value: 0), action: .unsubscribe)
        commentsRequest = ReaderTopicServiceSubscriptionsRequest.comments(siteId: NSNumber(value: 0), action: .update)
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
        XCTAssertEqual(postsEmailRequest.path, "read/sites/0/post_email_subscriptions/delete/")
    }
    
    func testCommentsRequest() {
        XCTAssertEqual(commentsRequest.apiVersion, ._1_2)
        XCTAssertEqual(commentsRequest.path, "read/sites/0/comment_email_subscriptions/update/")
    }
}
