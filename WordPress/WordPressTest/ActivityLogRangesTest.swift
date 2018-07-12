import XCTest
@testable import WordPress

final class ActivityLogRangesTests: XCTestCase {

    let testData = ActivityLogTestData()

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPostRangeCreatesURL() {
        let range = NSRange(location: 0, length: 0)
        let postRange = ActivityPostRange(range: range, siteID: testData.testSiteID, postID: testData.testPostID)

        XCTAssertEqual(testData.testPostUrl, postRange.url?.absoluteString)
    }

    func testPluginRangeCreatesURL() {
        let range = NSRange(location: 0, length: 0)
        let pluginRange = ActivityPluginRange(range: range, pluginSlug: testData.testPluginSlug, siteSlug: testData.testSiteSlug)

        XCTAssertEqual(pluginRange.url?.absoluteString, testData.testPluginUrl)
    }

    func testDefaultRange() {
        let range = NSRange(location: 0, length: 0)
        let url = URL(string: testData.testPostUrl)!

        let defaultRange = ActivityRange(range: range, url: url)

        XCTAssertEqual(defaultRange.kind, .default)
        XCTAssertEqual(defaultRange.url?.absoluteString, testData.testPostUrl)
        XCTAssertEqual(defaultRange.range, range)
    }

    func testRangeFactoryCreatesCommentRange() {
        let commentRangeRaw = testData.getCommentRangeDictionary()
        let range = ActivityRangesFactory.contentRange(from: commentRangeRaw)

        XCTAssertNotNil(range)
        XCTAssertTrue(range is ActivityRange)

        let commentRange = range as? ActivityRange

        XCTAssertEqual(commentRange?.kind, .comment)
        XCTAssertNotNil(commentRange?.url)
    }

    func testRangeFactoryCreatesThemeRange() {
        let themeRangeRaw = testData.getThemeRangeDictionary()
        let range = ActivityRangesFactory.contentRange(from: themeRangeRaw)

        XCTAssertNotNil(range)
        XCTAssertTrue(range is ActivityRange)

        let themeRange = range as? ActivityRange

        XCTAssertEqual(themeRange?.kind, .theme)
        XCTAssertNotNil(themeRange?.url)
    }

    func testRangeFactoryCreatesPostRange() {
        let postRangeRaw = testData.getPostRangeDictionary()

        let range = ActivityRangesFactory.contentRange(from: postRangeRaw)
        XCTAssertNotNil(range)
        XCTAssertEqual(range?.kind, .post)
        XCTAssertTrue(range is ActivityPostRange)

        let postRange = range as? ActivityPostRange

        XCTAssertEqual(postRange?.url?.absoluteString, testData.testPostUrl)
    }

    func testRangeFactoryCreatesItalicRange() {
        let italicRangeRaw = testData.getItalicRangeDictionary()

        let range = ActivityRangesFactory.contentRange(from: italicRangeRaw)
        XCTAssertNotNil(range)
        XCTAssertEqual(range?.kind, .italic)
    }

    func testRangeFactoryCreatesSiteRange() {
        let siteRangeRaw = testData.getSiteRangeDictionary()
        let range = ActivityRangesFactory.contentRange(from: siteRangeRaw)

        XCTAssertNotNil(range)
        XCTAssertEqual(range?.kind, .site)
    }

    func testRangeFactoryCreatesPluginRange() {
        let pluginRangeRaw = testData.getPluginRangeDictionary()
        let range = ActivityRangesFactory.contentRange(from: pluginRangeRaw)

        XCTAssertNotNil(range)
        XCTAssertEqual(range?.kind, .plugin)
        XCTAssertTrue(range is ActivityPluginRange)

        let pluginRange = range as? ActivityPluginRange

        XCTAssertEqual(pluginRange?.url?.absoluteString, testData.testPluginUrl)
    }
}
