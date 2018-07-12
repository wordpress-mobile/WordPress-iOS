import XCTest
@testable import WordPress

final class ActivityLogRangesTests: XCTestCase {

    let activityLogJSON = ActivityLogJSON()

    let testPostID = 441
    let testSiteID = 137726971
    var testPostUrl: String {
        return "https://wordpress.com/read/blogs/\(testSiteID)/posts/\(testPostID)"
    }

    let testPluginSlug = "wp-job-manager"
    let testSiteSlug = "etoledomatomicsite01.blog"

    var testPluginUrl: String {
        return "https://wordpress.com/plugins/\(testPluginSlug)/\(testSiteSlug)"
    }

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPostRangeCreatesURL() {
        let range = NSRange(location: 0, length: 0)
        let postRange = ActivityPostRange(range: range, siteID: testSiteID, postID: testPostID)

        XCTAssertEqual(testPostUrl, postRange.url?.absoluteString)
    }

    func testPluginRangeCreatesURL() {
        let range = NSRange(location: 0, length: 0)
        let pluginRange = ActivityPluginRange(range: range, pluginSlug: testPluginSlug, siteSlug: testSiteSlug)

        XCTAssertEqual(pluginRange.url?.absoluteString, testPluginUrl)
    }

    func testDefaultRange() {
        let range = NSRange(location: 0, length: 0)
        let url = URL(string: testPostUrl)!

        let defaultRange = ActivityRange(range: range, url: url)

        XCTAssertEqual(defaultRange.kind, .default)
        XCTAssertEqual(defaultRange.url, url)
        XCTAssertEqual(defaultRange.range, range)
    }

    func testRangeFactoryCreatesCommentRange() {
        let commentRangeRaw = activityLogJSON.getCommentRangeDictionary()
        let range = ActivityRangesFactory.contentRange(from: commentRangeRaw)

        XCTAssertNotNil(range)
        XCTAssertTrue(range! is ActivityCommentRange)

        let commentRange = range as! ActivityCommentRange

        XCTAssertEqual(commentRange.kind, .comment)
        XCTAssertNotNil(commentRange.url)
    }

    func testRangeFactoryCreatesThemeRange() {
        let themeRangeRaw = activityLogJSON.getThemeRangeDictionary()
        let range = ActivityRangesFactory.contentRange(from: themeRangeRaw)

        XCTAssertNotNil(range)
        XCTAssertTrue(range! is ActivityThemeRange)

        let themeRange = range as! ActivityThemeRange

        XCTAssertEqual(themeRange.kind, .theme)
        XCTAssertNotNil(themeRange.url)
    }

    func testRangeFactoryCreatesPostRange() {
        let postRangeRaw = activityLogJSON.getPostRangeDictionary()

        let range = ActivityRangesFactory.contentRange(from: postRangeRaw)
        XCTAssertNotNil(range)
        XCTAssertEqual(range?.kind, .post)
        XCTAssertTrue(range is ActivityPostRange)

        let postRange = range as? ActivityPostRange

        XCTAssertEqual(postRange?.url?.absoluteString, testPostUrl)
    }

    func testRangeFactoryCreatesItalicRange() {
        let italicRangeRaw = activityLogJSON.getItalicRangeDictionary()

        let range = ActivityRangesFactory.contentRange(from: italicRangeRaw)
        XCTAssertNotNil(range)
        XCTAssertEqual(range?.kind, .italic)
    }

    func testRangeFactoryCreatesSiteRange() {
        let siteRangeRaw = activityLogJSON.getSiteRangeDictionary()
        let range = ActivityRangesFactory.contentRange(from: siteRangeRaw)

        XCTAssertNotNil(range)
        XCTAssertEqual(range?.kind, .site)
    }

    func testRangeFactoryCreatesPluginRange() {
        let pluginRangeRaw = activityLogJSON.getPluginRangeDictionary()
        let range = ActivityRangesFactory.contentRange(from: pluginRangeRaw)

        XCTAssertNotNil(range)
        XCTAssertEqual(range?.kind, .plugin)
        XCTAssertTrue(range is ActivityPluginRange)

        let pluginRange = range as? ActivityPluginRange

        XCTAssertEqual(pluginRange?.url?.absoluteString, testPluginUrl)
    }
}
