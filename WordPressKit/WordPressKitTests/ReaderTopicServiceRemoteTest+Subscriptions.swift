import XCTest
@testable import WordPressKit


class ReaderTopicServiceRemoteTestSubscriptions: XCTestCase {
    let mockRemoteApi = MockWordPressComRestApi()
    let response = [String: AnyObject]()
    let siteId = 0
    var failure: ((ReaderTopicServiceError?) -> Void)!
    var readerTopicServiceRemote: ReaderTopicServiceRemote!
    
    override func setUp() {
        super.setUp()
        readerTopicServiceRemote = ReaderTopicServiceRemote(wordPressComRestApi: mockRemoteApi)
        failure = { _ in
            fatalError()
        }
    }
    
    func testSubscribeNotification() {
        var success = false
        let expectedPath = "wpcom/v2/read/sites/0/notification-subscriptions/new/"
        readerTopicServiceRemote.subscribeSiteNotifications(with: siteId, {
            success = true
        }, failure)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertTrue(success)
    }
    
    func testUnsubscribeNotification() {
        var success = false
        let expectedPath = "wpcom/v2/read/sites/0/notification-subscriptions/delete/"
        readerTopicServiceRemote.unsubscribeSiteNotifications(with: siteId, {
            success = true
        }, failure)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertTrue(success)
    }
    
    func testSubscribeComments() {
        var success = false
        let expectedPath = "rest/v1.2/read/site/0/comment_email_subscriptions/new/"
        readerTopicServiceRemote.subscribeSiteComments(with: siteId, {
            success = true
        }, failure)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertTrue(success)
    }
    
    func testUnsubscribeComments() {
        var success = false
        let expectedPath = "rest/v1.2/read/site/0/comment_email_subscriptions/delete/"
        readerTopicServiceRemote.unsubscribeSiteComments(with: siteId, {
            success = true
        }, failure)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertTrue(success)
    }
    
    func testSubscribePostsEmail() {
        var success = false
        let expectedPath = "rest/v1.2/read/site/0/post_email_subscriptions/new/"
        readerTopicServiceRemote.subscribePostsEmail(with: siteId, {
            success = true
        }, failure)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertTrue(success)
    }
    
    func testUnsubscribePostsEmail() {
        var success = false
        let expectedPath = "rest/v1.2/read/site/0/post_email_subscriptions/delete/"
        readerTopicServiceRemote.unsubscribePostsEmail(with: siteId, {
            success = true
        }, failure)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertTrue(success)
    }
    
    func testUdatePostsEmail() {
        var success = false
        let expectedPath = "rest/v1.2/read/site/0/post_email_subscriptions/update/"
        
        readerTopicServiceRemote.updateFrequencyPostsEmail(with: siteId, frequency: .weekly, {
            success = true
        }, failure)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
        mockRemoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())
        XCTAssertTrue(success)
        
        guard let parameters = mockRemoteApi.parametersPassedIn as? [String: AnyObject],
            let frequency = parameters["delivery_frequency"] as? String else {
            fatalError()
        }
        
        XCTAssertEqual(frequency, ReaderServiceDeliveryFrequency.weekly.rawValue)
    }
}
