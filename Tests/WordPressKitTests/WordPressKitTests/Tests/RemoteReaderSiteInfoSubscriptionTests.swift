import XCTest
@testable import WordPressKit

class RemoteReaderSiteInfoSubscriptionTests: XCTestCase {
    func testRemoteReaderSiteInfoSubscriptionPost() {
        let postSubscription = RemoteReaderSiteInfoSubscriptionPost(dictionary: ["send_posts": false])
        XCTAssertNotNil(postSubscription)
        XCTAssertFalse(postSubscription.sendPosts)
    }

    func testRemoteReaderSiteInfoSubscriptionEmail() {
        let emailSubscription = RemoteReaderSiteInfoSubscriptionEmail(dictionary: ["send_posts": true,
                                                                                   "send_comments": false,
                                                                                   "post_delivery_frequency": "instantly"])
        XCTAssertNotNil(emailSubscription)
        XCTAssertFalse(emailSubscription.sendComments)
        XCTAssertTrue(emailSubscription.sendPosts)
        XCTAssertEqual("instantly", emailSubscription.postDeliveryFrequency)
    }
}
