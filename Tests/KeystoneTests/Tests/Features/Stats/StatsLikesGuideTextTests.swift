import Foundation
import Testing
import UIKit
import WordPressKit
@testable import WordPress

@MainActor
@Suite("Stats likes guide text")
struct StatsLikesGuideTextTests {
    @Test("uses the same wording for any count", arguments: [0, 1, 21])
    func sameWordingForAnyCount(count: Int) throws {
        let text = try #require(likesGuideText(count: count))
        #expect(text.string == "Likes on the latest post My Post: \(count)")
    }

    @Test("bolds the count")
    func boldsTheCount() throws {
        let text = try #require(likesGuideText(count: 21))
        let countLocation = (text.string as NSString).range(of: "21").location

        let font = try #require(text.attribute(.font, at: countLocation, effectiveRange: nil) as? UIFont)
        #expect(font.fontDescriptor.symbolicTraits.contains(.traitBold))
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
