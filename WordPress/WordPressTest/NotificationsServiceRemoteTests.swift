import Foundation
import XCTest


class NotificationsServiceRemoteTests : XCTestCase
{
    var remoteApi: WordPressComApi?
    let timeout = 2.0
    
    override func setUp() {
        super.setUp()
        remoteApi = WordPressComApi.anonymousApi()
        
        // Mock Settings request
        OHHTTPStubs.shouldStubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
                let settingsRange = request?.URL?.absoluteString?.rangeOfString("notifications/settings/")
                return settingsRange != nil
            },
            withStubResponse: { (request: NSURLRequest!) -> OHHTTPStubsResponse! in
                return OHHTTPStubsResponse(file:"notifications-settings.json",
                                    contentType:"application/json",
                                   responseTime:OHHTTPStubsDownloadSpeedWifi)
        })
    }
    
    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllRequestHandlers()
    }
    
    func testGetAllSettingsReturnsValidNotificationSettings() {
        let remote      = NotificationsServiceRemote(api: remoteApi)
        let expectation = expectationWithDescription(nil)
        
        remote?.getAllSettings({
                (settings: RemoteNotificationsSettings) in
                expectation.fulfill()
// TODO: Validate settings object
            },
            failure: {
                (error: NSError!) in
                XCTAssert(true, "Error while getting all settings")
                expectation.fulfill()
            })
        
        waitForExpectationsWithTimeout(timeout, handler: nil)
    }
}
