import XCTest
@testable import WordPress

final class StatsTotalInsightsCellTests: XCTestCase {

    func testRangeOfDifferenceSubtringWhenDifferenceAtTheStart() {
        let string = "*+1 (1%)* higher than the previous 7-days"
        let range = StatsTotalInsightsCell.rangeOfDifferenceSubstring(string)

        let startIndex = string.startIndex
        let endIndex = string.index(startIndex, offsetBy: 7)
        let expectedRange = startIndex..<endIndex

        XCTAssertEqual(range, expectedRange)
    }

    func testRangeOfDifferenceSubtringWhenDifferenceAtTheEnd() {
        let string = "Higher than the previous 7-days by *+1 (1%)*"
        let range = StatsTotalInsightsCell.rangeOfDifferenceSubstring(string)

        let startIndex = string.index(string.startIndex, offsetBy: 35)
        let endIndex = string.index(startIndex, offsetBy: 7)
        let expectedRange = startIndex..<endIndex

        XCTAssertEqual(range, expectedRange)
    }

    func testRangeOfDifferenceSubtringWhenDifferenceAtTheMiddle() {
        let string = "Higher by *+1 (1%)* compared to the previous 7-days"
        let range = StatsTotalInsightsCell.rangeOfDifferenceSubstring(string)

        let startIndex = string.index(string.startIndex, offsetBy: 10)
        let endIndex = string.index(startIndex, offsetBy: 7)
        let expectedRange = startIndex..<endIndex

        XCTAssertEqual(range, expectedRange)
    }
}
