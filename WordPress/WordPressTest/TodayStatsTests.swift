@testable import WordPress
@testable import WordPressKit

class TodayStatsTests: StatsTestCase {


    func testInsertingMultipleFails() {
        mainContext.reset()

        let parent = createStatsRecord(in: mainContext, type: .today, date: Date())
        let child1 = TodayStatsRecordValue(parent: parent)
        child1.commentsCount = 9
        child1.viewsCount = 0
        child1.visitorsCount = 0
        child1.likesCount = 1

        let child2 = TodayStatsRecordValue(parent: parent)
        child2.commentsCount = 9
        child2.viewsCount = 0
        child2.visitorsCount = 0
        child2.likesCount = 2

        XCTAssertThrowsError(try mainContext.save()) { error in
            // the error is being bubbled up through Obj-C Core Data innards, which means we can't just compare the enums.
            let thrownErrorAsNSError = error as NSError
            let expectedErrorAsNSErrror = StatsCoreDataValidationError.singleEntryTypeViolation as NSError

            let underlyingErrors = thrownErrorAsNSError.userInfo[NSDetailedErrorsKey] as! [NSError]

            XCTAssertEqual(underlyingErrors.count, 2, "should be as many as objects being attempted to insert")
            XCTAssertEqual(underlyingErrors.first!.domain, expectedErrorAsNSErrror.domain)
            XCTAssertEqual(underlyingErrors.first!.code, expectedErrorAsNSErrror.code)
            XCTAssert(true)
        }
    }

    func testCoreDataConversion() {
        let insight = StatsTodayInsight(viewsCount: 9001, visitorsCount: 9002, likesCount: 9003, commentsCount: 9004)

        let blog = defaultBlog

        _ = StatsRecord.record(from: insight, for: blog)

        XCTAssertNoThrow(try mainContext.save())

        let fetchRequest = StatsRecord.fetchRequest(for: .today)
        let result = try! mainContext.fetch(fetchRequest)
        let statsRecord = result.first!

        XCTAssertEqual(statsRecord.blog, blog)
        XCTAssertEqual(statsRecord.period, StatsRecordPeriodType.notApplicable.rawValue)

        let castedResults = statsRecord.values?.array.first! as! TodayStatsRecordValue

        XCTAssertEqual(castedResults.viewsCount, 9001)
        XCTAssertEqual(castedResults.visitorsCount, 9002)
        XCTAssertEqual(castedResults.likesCount, 9003)
        XCTAssertEqual(castedResults.commentsCount, 9004)
    }

}
