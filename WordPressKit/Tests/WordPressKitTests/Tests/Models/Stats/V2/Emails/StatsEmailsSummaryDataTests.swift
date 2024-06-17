import XCTest
@testable import WordPressKit

final class StatsEmailsSummaryDataTests: XCTestCase {
    func testEmailsSummaryDecoding() throws {
        let json = getJSON("stats-emails-summary")

        let emailsSummary = StatsEmailsSummaryData(jsonDictionary: json)
        XCTAssertNotNil(emailsSummary, "StatsEmailsSummaryTimeIntervalData not decoded as expected")
        let post = emailsSummary!.posts[0]

        XCTAssertEqual(emailsSummary?.posts.count, 4)
        XCTAssertEqual(post.link, URL(string: "https://www.test1.com"))
        XCTAssertEqual(post.title, "A great testing post")
        XCTAssertEqual(post.type, .post)
        XCTAssertEqual(post.clicks, 2202)
        XCTAssertEqual(post.opens, 453192)
    }
}

private extension StatsEmailsSummaryDataTests {
    func getJSON(_ fileName: String) -> [String: AnyObject] {
        let path = Bundle(for: type(of: self)).path(forResource: fileName, ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
    }
}
