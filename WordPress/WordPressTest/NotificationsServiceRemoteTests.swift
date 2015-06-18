import Foundation
import XCTest


class NotificationsServiceRemoteTests : XCTestCase
{
    let remoteApi           = WordPressComApi.anonymousApi()
    let timeout             = 2.0
    let contentTypeJson     = "application/json"
    let settingsEndpoint    = "notifications/settings/"
    let settingsFilename    = "notifications-settings.json"
    
    override func setUp() {
        super.setUp()
        
        OHHTTPStubs.shouldStubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
                return request?.URL?.absoluteString?.rangeOfString(self.settingsEndpoint) != nil
            },
            withStubResponse: { (request: NSURLRequest!) -> OHHTTPStubsResponse! in
                return OHHTTPStubsResponse(file: self.settingsFilename, contentType: self.contentTypeJson, responseTime: OHHTTPStubsDownloadSpeedWifi)
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
