import XCTest
@testable import WordPress

final class ActivityLogRangesTests: XCTestCase {

    let activityLogJSON = ActivityLogJSON()

    let testPostID = 347
    let testSiteID = 137726971
    var testPostURL: String {
        return "https://wordpress.com/read/blogs/\(testSiteID)/posts/\(testPostID)"
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

        XCTAssertEqual(testPostURL, postRange.url?.absoluteString)
    }

    func testDefaultRange() {
        let range = NSRange(location: 0, length: 0)
        let url = URL(string: testPostURL)!

        let defaultRange = ActivityRange(range: range, url: url)

        XCTAssertEqual(defaultRange.kind, .default)
        XCTAssertEqual(defaultRange.url, url)
        XCTAssertEqual(defaultRange.range, range)
    }

    func testCommentRange() {
        let commentRangeRaw = activityLogJSON.getCommentRangeDictionary()
        let range = ActivityRangesFactory.contentRange(from: commentRangeRaw)

        XCTAssertNotNil(range)
        XCTAssertTrue(range! is ActivityCommentRange)

        let commentRange = range as! ActivityCommentRange

        XCTAssertEqual(commentRange.kind, .comment)
        XCTAssertNotNil(commentRange.url)
    }

    func testRangeFactoryCreatePostRange() {
        let postRangeRaw = activityLogJSON.getPostRangeDictionary()

        let factory = ActivityRangesFactory.contentRange(from: postRangeRaw)
        XCTAssertNotNil(factory)
        XCTAssertEqual(factory?.kind, .post)
    }
}
