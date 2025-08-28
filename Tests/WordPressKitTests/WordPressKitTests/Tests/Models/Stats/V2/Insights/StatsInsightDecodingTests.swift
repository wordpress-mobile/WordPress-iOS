import XCTest
import WordPressKit

final class StatsInsightDecodingTests: XCTestCase {
    private struct StatsInsightEntity {
        let type: StatsInsightData.Type
        let fileName: String
    }

    private let testEntities: [StatsInsightEntity] = [
        .init(type: StatsLastPostInsight.self, fileName: "stats-insight-last-post"),
        .init(type: StatsDotComFollowersInsight.self, fileName: "stats-insight-followers"),
        .init(type: StatsEmailFollowersInsight.self, fileName: "stats-insight-followers"),
        .init(type: StatsAllTimesInsight.self, fileName: "stats"),
        .init(type: StatsAllAnnualInsight.self, fileName: "stats-insight"),
        .init(type: StatsAnnualAndMostPopularTimeInsight.self, fileName: "stats-insight"),
        .init(type: StatsPublicizeInsight.self, fileName: "stats-insight-publicize"),
        .init(type: StatsTodayInsight.self, fileName: "stats-insight-summary"),
        .init(type: StatsCommentsInsight.self, fileName: "stats-insight-comments"),
        .init(type: StatsTagsAndCategoriesInsight.self, fileName: "stats-insight-tag-and-category"),
        .init(type: StatsPostingStreakInsight.self, fileName: "stats-insight-streak"),
    ]

    func testStatsInsightEntitiesDecoding() throws {
        for entitity in testEntities {
            let json = getJSON(entitity.fileName)
            XCTAssertNotNil(entitity.type.init(jsonDictionary: json), "Entity \(entitity.type) cannot be decoded from \(entitity.fileName)")
        }
    }
}

private extension StatsInsightDecodingTests {
    func getJSON(_ fileName: String) -> [String: AnyObject] {
        let path = Bundle(for: type(of: self)).path(forResource: fileName, ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
    }
}
