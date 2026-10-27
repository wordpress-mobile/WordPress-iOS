import UIKit
import WordPressKit
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

    func testLikesGuideTextUsesTheSameWordingForAnyCount() throws {
        for count in [0, 1, 21] {
            let text = try XCTUnwrap(likesGuideText(count: count))
            XCTAssertEqual(text.string, "Likes on the latest post My Post: \(count)")
        }
    }

    func testLikesGuideTextBoldsTheCount() throws {
        let text = try XCTUnwrap(likesGuideText(count: 21))
        let countLocation = (text.string as NSString).range(of: "21").location

        let font = try XCTUnwrap(text.attribute(.font, at: countLocation, effectiveRange: nil) as? UIFont)
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    private func likesGuideText(count: Int) -> NSAttributedString? {
        let insight = StatsLastPostInsight(
            title: "My Post",
            url: URL(string: "https://example.com/my-post")!,
            publishedDate: Date(),
            likesCount: count,
            commentsCount: 0,
            viewsCount: 0,
            postID: 1,
            featuredImageURL: nil
        )
        return StatsTotalInsightsData.makeTotalInsightsGuideText(lastPostInsight: insight, statsSummaryType: .likes)
    }
}
