@testable import WordPress
@testable import WordPressKit

class AllTimeStatsRecordValueTests: StatsTestCase {

    func testCoreDataConversion() {
        let date = Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2018, month: 2, day: 28))!

        let insight = StatsAllTimesInsight(postsCount: 9001,
                                           viewsCount: 9002,
                                           bestViewsDay: date,
                                           visitorsCount: 9003,
                                           bestViewsPerDayCount: 9004)

        let blog = defaultBlog

        _ = StatsRecord.record(from: insight, for: blog)

        XCTAssertNoThrow(try mainContext.save())

        let fetchRequest = StatsRecord.fetchRequest(for: .allTimeStatsInsight)
        let result = try! mainContext.fetch(fetchRequest)
        let statsRecord = result.first!

        XCTAssertEqual(statsRecord.blog, blog)
        XCTAssertEqual(statsRecord.period, StatsRecordPeriodType.notApplicable.rawValue)

        let castedResults = statsRecord.values?.array.first! as! AllTimeStatsRecordValue

        XCTAssertEqual(castedResults.postsCount, 9001)
        XCTAssertEqual(castedResults.viewsCount, 9002)
        XCTAssertEqual(castedResults.visitorsCount, 9003)
        XCTAssertEqual(castedResults.bestViewsPerDayCount, 9004)
        XCTAssertEqual(castedResults.bestViewsDay, date as NSDate)
    }

}
