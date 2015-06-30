import Foundation
import XCTest


class NotificationsServiceRemoteTests : XCTestCase
{
    typealias Kind          = RemoteNotificationSettings.StreamKind
    
    // MARK: - Properties
    var contextManager      : TestContextManager!
    var remoteApi           : WordPressComApi!
    
    // MARK: - Constants
    let timeout             = 2.0
    let contentTypeJson     = "application/json"
    let settingsEndpoint    = "notifications/settings/"
    let settingsFilename    = "notifications-settings.json"
    let dummyDeviceId       = "1234"

    
    // MARK: - Overriden Methods
    override func setUp() {
        super.setUp()
        
        contextManager  = TestContextManager()
        remoteApi       = WordPressComApi.anonymousApi()
        
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
    
    
    // MARK: - Unit Tests!
    func testNotificationSettingsCorretlyParsesThreeSiteEntities() {
        
        let settings                = loadNotificationSettings()
        let sites                   = settings.sites
        let siteDeviceSettings      = sites.filter { $0.streamKind == Kind.Device }.first
        let siteEmailSettings       = sites.filter { $0.streamKind == Kind.Email }.first
        let siteTimelineSettings    = sites.filter { $0.streamKind == Kind.Timeline }.first

        XCTAssert(sites.count == 3,                                 "Error while parsing Site Settings")
        
        XCTAssert(siteDeviceSettings?.newComment == false,          "Error while parsing Site Device Settings")
        XCTAssert(siteDeviceSettings?.commentLike == true,          "Error while parsing Site Device Settings")
        XCTAssert(siteDeviceSettings?.postLike == false,            "Error while parsing Site Device Settings")
        XCTAssert(siteDeviceSettings?.follow == true,               "Error while parsing Site Device Settings")
        XCTAssert(siteDeviceSettings?.achievement == false,         "Error while parsing Site Device Settings")
        XCTAssert(siteDeviceSettings?.mentions == true,             "Error while parsing Site Device Settings")

        XCTAssert(siteEmailSettings?.newComment == true,            "Error while parsing Site Email Settings")
        XCTAssert(siteEmailSettings?.commentLike == false,          "Error while parsing Site Email Settings")
        XCTAssert(siteEmailSettings?.postLike == true,              "Error while parsing Site Email Settings")
        XCTAssert(siteEmailSettings?.follow == false,               "Error while parsing Site Email Settings")
        XCTAssert(siteEmailSettings?.achievement == true,           "Error while parsing Site Email Settings")
        XCTAssert(siteEmailSettings?.mentions == false,             "Error while parsing Site Email Settings")
        
        XCTAssert(siteTimelineSettings?.newComment == false,        "Error while parsing Site Timeline Settings")
        XCTAssert(siteTimelineSettings?.commentLike == true,        "Error while parsing Site Timeline Settings")
        XCTAssert(siteTimelineSettings?.postLike == false,          "Error while parsing Site Timeline Settings")
        XCTAssert(siteTimelineSettings?.follow == true,             "Error while parsing Site Timeline Settings")
        XCTAssert(siteTimelineSettings?.achievement == false,       "Error while parsing Site Timeline Settings")
        XCTAssert(siteTimelineSettings?.mentions == true,           "Error while parsing Site Timeline Settings")
    }
    
    func testNotificationSettingsCorretlyParsesThreeOtherEntities() {
        
        let settings                = loadNotificationSettings()
        let other                   = settings.other
        let otherDeviceSettings     = other.filter { $0.streamKind == Kind.Device }.first
        let otherEmailSettings      = other.filter { $0.streamKind == Kind.Email }.first
        let otherTimelineSettings   = other.filter { $0.streamKind == Kind.Timeline }.first
        
        XCTAssert(otherDeviceSettings?.commentLike == true,         "Error while parsing Other Device Settings")
        XCTAssert(otherDeviceSettings?.commentReply == true,        "Error while parsing Other Device Settings")

        XCTAssert(otherEmailSettings?.commentLike == false,         "Error while parsing Other Email Settings")
        XCTAssert(otherEmailSettings?.commentReply == false,        "Error while parsing Other Email Settings")

        XCTAssert(otherTimelineSettings?.commentLike == false,      "Error while parsing Other Timeline Settings")
        XCTAssert(otherTimelineSettings?.commentReply == true,      "Error while parsing Other Timeline Settings")
    }
    
    func testNotificationSettingsCorretlyParsesDotcomSettings() {
        
        let settings                = loadNotificationSettings()
        let wordPressComSettings    = settings.wpcom.first!
        
        XCTAssert(wordPressComSettings.news == false,               "Error while parsing WordPress.com Settings")
        XCTAssert(wordPressComSettings.recommendations == false,    "Error while parsing WordPress.com Settings")
        XCTAssert(wordPressComSettings.promotion == true,           "Error while parsing WordPress.com Settings")
        XCTAssert(wordPressComSettings.digest == true,              "Error while parsing WordPress.com Settings")
    }
    
    
    // MARK: - Private Helpers
    private func loadNotificationSettings() -> RemoteNotificationSettings {
        let remote      = NotificationsServiceRemote(api: remoteApi)
        var settings : RemoteNotificationSettings?
        
        let expectation = expectationWithDescription(nil)
        
        remote?.getAllSettings(dummyDeviceId,
            success: { (theSettings: RemoteNotificationSettings) in
                settings = theSettings
                expectation.fulfill()
            },
            failure: { (error: NSError!) in
                expectation.fulfill()
            })
        
        waitForExpectationsWithTimeout(timeout, handler: nil)
        
        XCTAssert(settings != nil, "Error while parsing settings")
        
        return settings!
    }
}
