@testable import WordPress
@testable import WordPressKit

class AnnualAndMostPopularTimeStatsRecordValueTests: StatsTestCase {

    func testCoreDataConversion() {
        let insight = StatsAnnualAndMostPopularTimeInsight(mostPopularDayOfWeek: DateComponents(weekday: 3),
                                                           mostPopularDayOfWeekPercentage: 15,

                                                           mostPopularHour: DateComponents(hour: 16),
                                                           mostPopularHourPercentage: 99,

                                                           annualInsightsYear: 2018,
                                                           annualInsightsTotalPostsCount: 9001,

                                                           annualInsightsTotalWordsCount: 9002,
                                                           annualInsightsAverageWordsCount: 2.5,

                                                           annualInsightsTotalLikesCount: 9003,
                                                           annualInsightsAverageLikesCount: 3.5,

                                                           annualInsightsTotalCommentsCount: 9004,
                                                           annualInsightsAverageCommentsCount: 4.5,

                                                           annualInsightsTotalImagesCount: 9005,
                                                           annualInsightsAverageImagesCount: 5.5)

        let blog = defaultBlog

        _ = StatsRecord.record(from: insight, for: blog)

        XCTAssertNoThrow(try mainContext.save())

        let statsRecord = StatsRecord.insight(for: blog, type: .annualAndMostPopularTimes)

        XCTAssertNotNil(statsRecord)

        XCTAssertEqual(statsRecord!.blog, blog)
        XCTAssertEqual(statsRecord!.period, StatsRecordPeriodType.notApplicable.rawValue)

        let castedResults = statsRecord!.values?.array.first! as! AnnualAndMostPopularTimeStatsRecordValue

        XCTAssertEqual(castedResults.mostPopularDayOfWeek, 3)
        XCTAssertEqual(castedResults.mostPopularDayOfWeekPercentage, 15)

        XCTAssertEqual(castedResults.mostPopularHour, 16)
        XCTAssertEqual(castedResults.mostPopularHourPercentage, 99)

        XCTAssertEqual(castedResults.insightYear, 2018)
        XCTAssertEqual(castedResults.totalPostsCount, 9001)

        XCTAssertEqual(castedResults.totalWordsCount, 9002)
        XCTAssertEqual(castedResults.averageWordsCount, 2.5)

        XCTAssertEqual(castedResults.totalLikesCount, 9003)
        XCTAssertEqual(castedResults.averageLikesCount, 3.5)

        XCTAssertEqual(castedResults.totalCommentsCount, 9004)
        XCTAssertEqual(castedResults.averageCommentsCount, 4.5)

        XCTAssertEqual(castedResults.totalImagesCount, 9005)
        XCTAssertEqual(castedResults.averageImagesCount, 5.5)
    }

}
