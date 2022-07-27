import XCTest
@testable import WordPress

class WeeklyRoundupBackgroundTaskTests: XCTestCase {

    private var task: WeeklyRoundupBackgroundTask!

    override func setUpWithError() throws {
        task = WeeklyRoundupBackgroundTask()
    }

    func testNotificationTitleEmpty() throws {
        // Given a site
        // When title is nil
        let emptySiteTitle: String? = nil

        // Then return a staticNotificationTitle
        XCTAssertEqual(task.notificationScheduler.notificationTitle(emptySiteTitle), WeeklyRoundupNotificationScheduler.TextContent.staticNotificationTitle)
    }

    func testNotificationTitleIsNumber() throws {
        // Given a site
        // When title is a numbered string
        let siteTitle: String? = "88"

        guard let unwrappedSiteTitle = siteTitle else {
            XCTFail()
            return
        }

        // Then return a dynamicNotificationTitle
        XCTAssertEqual(task.notificationScheduler.notificationTitle(siteTitle),
                       String(format: WeeklyRoundupNotificationScheduler.TextContent.dynamicNotificationTitle, unwrappedSiteTitle))
    }

    func testNotificationTitle() throws {
        // Given a site
        // When title is a valid string
        let siteTitle: String? = "fieldguide"

        guard let unwrappedSiteTitle = siteTitle else {
            XCTFail()
            return
        }

        // Then return a dynamicNotificationTitle
        XCTAssertEqual(task.notificationScheduler.notificationTitle(siteTitle),
                       String(format: WeeklyRoundupNotificationScheduler.TextContent.dynamicNotificationTitle, unwrappedSiteTitle))
    }

    func testNotificationTitleIsDiacritic() throws {
        // Given a site
        // When title is a diacritic string
        let siteTitle: String? = "crème brûlée"

        guard let unwrappedSiteTitle = siteTitle else {
            XCTFail()
            return
        }

        // Then return a dynamicNotificationTitle
        XCTAssertEqual(task.notificationScheduler.notificationTitle(siteTitle),
                       String(format: WeeklyRoundupNotificationScheduler.TextContent.dynamicNotificationTitle, unwrappedSiteTitle))
    }

    func testNotificationTitleIsDisplayURL() throws {
        // Given a site
        // When title is blog displayURL
        let siteTitle: String? = "wp.koke.me/sub"

        guard let unwrappedSiteTitle = siteTitle else {
            XCTFail()
            return
        }

        // Then return a dynamicNotificationTitle
        XCTAssertEqual(task.notificationScheduler.notificationTitle(siteTitle),
                       String(format: WeeklyRoundupNotificationScheduler.TextContent.dynamicNotificationTitle, unwrappedSiteTitle))
    }
}
