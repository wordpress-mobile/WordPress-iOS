import CoreData
import XCTest
import WordPressData
import WordPressShared

@testable import WordPress

/// End-to-end coverage for attaching a site to an event via `WPAnalytics.track(_:properties:blog:)`.
///
/// Confirms the `Blog` snapshot reaches the emitted event as `blog_id` / `site_type`,
/// and that `blog_id` arrives as a number (a Swift `Int` bridges to `NSNumber` at the
/// Objective-C tracker boundary).
final class BlogAnalyticsTrackingTests: CoreDataTestCase {

    override func setUp() {
        super.setUp()
        TestAnalyticsTracker.setup()
    }

    override func tearDown() {
        TestAnalyticsTracker.tearDown()
        super.tearDown()
    }

    func testTrackAttachesBlogIDAndP2SiteType() throws {
        let blog = BlogBuilder(mainContext, dotComID: 100)
            .with(isWPForTeamsSite: true)
            .build()

        WPAnalytics.track(.dashboardCardShown, properties: ["type": "post"], blog: blog)

        let tracked = try XCTUnwrap(TestAnalyticsTracker.tracked.last)
        let blogID: Int? = tracked.value(for: "blog_id")
        XCTAssertEqual(blogID, 100)
        XCTAssertEqual(tracked.value(for: "site_type"), "p2")
        XCTAssertEqual(tracked.value(for: "type"), "post")
    }

    func testTrackMarksNonP2SiteAsBlog() throws {
        let blog = BlogBuilder(mainContext, dotComID: 200)
            .with(isWPForTeamsSite: false)
            .build()

        WPAnalytics.track(.dashboardCardShown, blog: blog)

        let tracked = try XCTUnwrap(TestAnalyticsTracker.tracked.last)
        let blogID: Int? = tracked.value(for: "blog_id")
        XCTAssertEqual(blogID, 200)
        XCTAssertEqual(tracked.value(for: "site_type"), "blog")
    }

    func testSelfHostedSiteTracksWithoutBlogID() throws {
        let blog = BlogBuilder(mainContext, dotComID: nil).build()

        WPAnalytics.track(.dashboardCardShown, blog: blog)

        let tracked = try XCTUnwrap(TestAnalyticsTracker.tracked.last)
        let blogID: Int? = tracked.value(for: "blog_id")
        XCTAssertNil(blogID)
        XCTAssertEqual(tracked.value(for: "site_type"), "blog")
    }
}
