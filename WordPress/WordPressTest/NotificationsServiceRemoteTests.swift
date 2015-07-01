import Foundation
import XCTest


class NotificationsServiceRemoteTests : XCTestCase
{
    typealias StreamKind = RemoteNotificationSettings.Stream.Kind
    
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
        
        contextManager      = TestContextManager()
        remoteApi           = WordPressComApi.anonymousApi()
        
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
    func testNotificationSettingsCorrectlyParsesThreeSiteEntities() {
        
        let targetChannel   = RemoteNotificationSettings.Channel.Site(siteId: 1)
        let targetSettings  = loadNotificationSettings().filter { $0.channel == targetChannel }
        XCTAssert(targetSettings.count == 1, "Error while parsing Site Settings")
        
        let targetSite = targetSettings.first!
        XCTAssert(targetSite.streams.count == 3, "Error while parsing Site Stream Settings")
        
        let parsedDeviceSettings    = targetSite.streams.filter { $0.kind == StreamKind.Device }.first
        let parsedEmailSettings     = targetSite.streams.filter { $0.kind == StreamKind.Email }.first
        let parsedTimelineSettings  = targetSite.streams.filter { $0.kind == StreamKind.Timeline }.first

        let expectedTimelineSettings = [
            "new-comment"   : false,
            "comment-like"  : true,
            "post-like"     : false,
            "follow"        : true,
            "achievement"   : false,
            "mentions"      : true
        ]
        
        let expectedEmailSettings = [
            "new-comment"   : true,
            "comment-like"  : false,
            "post-like"     : true,
            "follow"        : false,
            "achievement"   : true,
            "mentions"      : false
        ]
        
        let expectedDeviceSettings = [
            "new-comment"   : false,
            "comment-like"  : true,
            "post-like"     : false,
            "follow"        : true,
            "achievement"   : false,
            "mentions"      : true
        ]
        
        for (key, value) in parsedDeviceSettings!.preferences! {
            XCTAssert(expectedDeviceSettings[key]! == value, "Error while parsing Site Device Settings")
        }
        
        for (key, value) in parsedEmailSettings!.preferences! {
            XCTAssert(expectedEmailSettings[key]! == value, "Error while parsing Site Email Settings")
        }
        
        for (key, value) in parsedTimelineSettings!.preferences! {
            XCTAssert(expectedTimelineSettings[key]! == value, "Error while parsing Site Timeline Settings")
        }
    }
    
    func testNotificationSettingsCorrectlyParsesThreeOtherEntities() {
        let filteredSettings = loadNotificationSettings().filter { $0.channel == .Other }
        XCTAssert(filteredSettings.count == 1, "Error while parsing Other Settings")
        
        let otherSettings = filteredSettings.first!
        XCTAssert(otherSettings.streams.count == 3, "Error while parsing Other Streams")
        
        let parsedDeviceSettings    = otherSettings.streams.filter { $0.kind == StreamKind.Device }.first
        let parsedEmailSettings     = otherSettings.streams.filter { $0.kind == StreamKind.Email }.first
        let parsedTimelineSettings  = otherSettings.streams.filter { $0.kind == StreamKind.Timeline }.first
        
        let expectedDeviceSettings = [
            "comment-like"  : true,
            "comment-reply" : true
        ]
        
        let expectedEmailSettings = [
            "comment-like"  : false,
            "comment-reply" : false
        ]
        
        let expectedTimelineSettings = [
            "comment-like"  : false,
            "comment-reply" : true
        ]

        for (key, value) in parsedDeviceSettings!.preferences! {
            XCTAssert(expectedDeviceSettings[key]! == value, "Error while parsing Other Device Settings")
        }
        
        for (key, value) in parsedEmailSettings!.preferences! {
            XCTAssert(expectedEmailSettings[key]! == value, "Error while parsing Other Email Settings")
        }
        
        for (key, value) in parsedTimelineSettings!.preferences! {
            XCTAssert(expectedTimelineSettings[key]! == value, "Error while parsing Other Timeline Settings")
        }
    }
    
    func testNotificationSettingsCorrectlyParsesDotcomSettings() {
        let filteredSettings = loadNotificationSettings().filter { $0.channel == .WordPressCom }
        XCTAssert(filteredSettings.count == 1, "Error while parsing WordPress.com Settings")
        
        let wordPressComSettings = filteredSettings.first!
        XCTAssert(wordPressComSettings.streams.count == 1, "Error while parsing WordPress.com Settings")
        
        let expectedSettings = [
            "news"          : false,
            "recommendation": false,
            "promotion"     : true,
            "digest"        : true
        ]
        
        for (key, value) in wordPressComSettings.streams.first!.preferences! {
            XCTAssert(expectedSettings[key]! == value, "Error while parsing WordPress.com Settings")
        }
    }
    
    
    
    // MARK: - Private Helpers
    private func loadNotificationSettings() -> [RemoteNotificationSettings] {
        let remote      = NotificationsServiceRemote(api: remoteApi)
        var settings : [RemoteNotificationSettings]?
        
        let expectation = expectationWithDescription(nil)
        
        remote?.getAllSettings(dummyDeviceId,
            success: { (theSettings: [RemoteNotificationSettings]) in
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
