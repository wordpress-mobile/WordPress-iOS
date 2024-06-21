import XCTest
@testable import WordPressKit

final class StatsSubscribersSummaryDataTests: XCTestCase {
    func testEmailsSummaryDecoding() throws {
        let json = getJSON("stats-subscribers")

        let summary = StatsSubscribersSummaryData(date: Date(), period: .day, jsonDictionary: json)
        XCTAssertNotNil(summary, "StatsSubscribersSummaryData not decoded as expected")
        let history = summary!.history
        let mostRecentDay = history.last!

        XCTAssertEqual(mostRecentDay.date, StatsSubscribersSummaryData.dateFormatter.date(from: "2024-04-22"))
        XCTAssertEqual(mostRecentDay.count, 77)
    }
}

private extension StatsSubscribersSummaryDataTests {
    func getJSON(_ fileName: String) -> [String: AnyObject] {
        let path = Bundle(for: type(of: self)).path(forResource: fileName, ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
    }
}
