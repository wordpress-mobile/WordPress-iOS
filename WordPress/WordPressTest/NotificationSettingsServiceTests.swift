import Foundation
import XCTest
import WordPress
import OHHTTPStubs


// MARK: - NotificationSettingsServiceTests
//
class NotificationSettingsServiceTests: XCTestCase {
    typealias StreamKind    = NotificationSettings.Stream.Kind

    // MARK: - Properties
    var contextManager: TestContextManager!
    var remoteApi: WordPressComRestApi!
    var service: NotificationSettingsService!

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
        remoteApi           = WordPressComRestApi(oAuthToken: nil, userAgent: nil)
        service             = NotificationSettingsService(managedObjectContext: contextManager.mainContext,
                                                           wordPressComRestApi: remoteApi)

        stub(condition: { request in
            return request.url?.absoluteString.range(of: self.settingsEndpoint) != nil
                && request.httpMethod! == "GET"
            }) { _ in
                let stubPath = OHPathForFile(self.settingsFilename, type(of: self))
                return fixture(filePath: stubPath!, headers: ["Content-Type" as NSObject: self.contentTypeJson as AnyObject])
        }
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        ContextManager.overrideSharedInstance(nil)
    }


    // MARK: - Unit Tests!
    func testNotificationSettingsCorrectlyParsesThreeSiteEntities() {

        let targetChannel   = NotificationSettings.Channel.blog(blogId: 1)
        let targetSettings  = loadNotificationSettings().filter { $0.channel == targetChannel }
        XCTAssert(targetSettings.count == 1, "Error while parsing Site Settings")

        let targetSite = targetSettings.first!
        XCTAssert(targetSite.streams.count == 3, "Error while parsing Site Stream Settings")

        let parsedDeviceSettings    = targetSite.streams.filter { $0.kind == StreamKind.Device }.first
        let parsedEmailSettings     = targetSite.streams.filter { $0.kind == StreamKind.Email }.first
        let parsedTimelineSettings  = targetSite.streams.filter { $0.kind == StreamKind.Timeline }.first

        let expectedTimelineSettings = [
            "new_comment": false,
            "comment_like": true,
            "post_like": false,
            "follow": true,
            "achievement": false,
            "mentions": true
        ]

        let expectedEmailSettings = [
            "new_comment": true,
            "comment_like": false,
            "post_like": true,
            "follow": false,
            "achievement": true,
            "mentions": false
        ]

        let expectedDeviceSettings = [
            "new_comment": false,
            "comment_like": true,
            "post_like": false,
            "follow": true,
            "achievement": false,
            "mentions": true
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
        let filteredSettings = loadNotificationSettings().filter { $0.channel == .other }
        XCTAssert(filteredSettings.count == 1, "Error while parsing Other Settings")

        let otherSettings = filteredSettings.first!
        XCTAssert(otherSettings.streams.count == 3, "Error while parsing Other Streams")

        let parsedDeviceSettings    = otherSettings.streams.filter { $0.kind == StreamKind.Device }.first
        let parsedEmailSettings     = otherSettings.streams.filter { $0.kind == StreamKind.Email }.first
        let parsedTimelineSettings  = otherSettings.streams.filter { $0.kind == StreamKind.Timeline }.first

        let expectedDeviceSettings = [
            "comment_like": true,
            "comment_reply": true
        ]

        let expectedEmailSettings = [
            "comment_like": false,
            "comment_reply": false
        ]

        let expectedTimelineSettings = [
            "comment_like": false,
            "comment_reply": true
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
        let filteredSettings = loadNotificationSettings().filter { $0.channel == .wordPressCom }
        XCTAssert(filteredSettings.count == 1, "Error while parsing WordPress.com Settings")

        let wordPressComSettings = filteredSettings.first!
        XCTAssert(wordPressComSettings.streams.count == 1, "Error while parsing WordPress.com Settings")

        let expectedSettings = [
            "news": false,
            "recommendation": false,
            "promotion": true,
            "digest": true
        ]

        for (key, value) in wordPressComSettings.streams.first!.preferences! {
            XCTAssert(expectedSettings[key]! == value, "Error while parsing WordPress.com Settings")
        }
    }



    // MARK: - Private Helpers
    fileprivate func loadNotificationSettings() -> [NotificationSettings] {
        var settings: [NotificationSettings]?
        let expect = expectation(description: "Notification settings reading expecation")

        service?.getAllSettings({ (theSettings: [NotificationSettings]) in
                settings = theSettings
                expect.fulfill()
            },
            failure: { (error: NSError?) in
                expect.fulfill()
            })

        waitForExpectations(timeout: timeout, handler: nil)

        XCTAssert(settings != nil, "Error while parsing settings")

        return settings!
    }
}
