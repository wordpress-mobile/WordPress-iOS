import Foundation
import XCTest


class NotificationsServiceRemoteTests : XCTestCase
{
    let remoteApi           = WordPressComApi.anonymousApi()
    let timeout             = 2.0
    let contentTypeJson     = "application/json"
    let settingsEndpoint    = "notifications/settings/"
    let settingsFilename    = "notifications-settings.json"
    let dummyDeviceId       = "1234"
    
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
        var settings : RemoteNotificationsSettings?
        
        // Simulate a Backend Call
        remote?.getAllSettings(dummyDeviceId, success: { (theSettings: RemoteNotificationsSettings) in
                settings = theSettings
                expectation.fulfill()
            },
            failure: { (error: NSError!) in
                expectation.fulfill()
            })
        
        // Wait till ready
        waitForExpectationsWithTimeout(timeout, handler: nil)
        
        // Validate that the parser works fine
        XCTAssertNotNil(settings, "Error while parsing settings")
        XCTAssert(settings?.sites.count == 6, "Error while parsing Site Settings")
        XCTAssert(settings?.other.count == 3, "Error while parsing Other Settings")
        XCTAssertNotNil(settings?.wpcom, "Error while parsing WordPress.com Settings")
        
        // Validate WordPress.com Settings
        let wordPressComSettings = settings!.wpcom!
        XCTAssert(wordPressComSettings.news == false, "Error while parsing WordPress.com Settings")
        XCTAssert(wordPressComSettings.recommendations == false, "Error while parsing WordPress.com Settings")
        XCTAssert(wordPressComSettings.promotion == true, "Error while parsing WordPress.com Settings")
        XCTAssert(wordPressComSettings.digest == true, "Error while parsing WordPress.com Settings")
    }
}
