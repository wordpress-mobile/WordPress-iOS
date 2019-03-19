@testable import WordPress
@testable import WordPressKit

// Note: This also tests a bunch of behavior that is actually provided by `StatsRecordValue` —
// but that's an a abstract entity and we can't instantiate it directly, so I put it together here.
class LastPostStatsRecordValueTests: StatsTestCase {

    // MARK: - StatsRecordValue tests
    func testEntityCreationWorks() {
        let parent = createStatsRecord(in: mainContext, type: .lastPostInsight, date: Date())
        createLastPostStatsRecordValue(parent: parent)

        let fetchRequest = StatsRecord.fetchRequest(for: .lastPostInsight)

        let result = try! mainContext.fetch(fetchRequest)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first!.values!.count, 1)
    }

    func testCastingWorks() {
        let parent = createStatsRecord(in: mainContext, type: .lastPostInsight, date: Date())
        createLastPostStatsRecordValue(parent: parent)

        let fetchRequest = StatsRecord.fetchRequest(for: .lastPostInsight)

        let result = try! mainContext.fetch(fetchRequest)

        let statsRecord = result.first!

        let castedResults = statsRecord.values?.array as? [LastPostStatsRecordValue]

        XCTAssertNotNil(castedResults)
        XCTAssertEqual(castedResults!.count, 1)
    }

    func testInverseRelationShipWorks() {
        let parent = createStatsRecord(in: mainContext, type: .lastPostInsight, date: Date())
        createLastPostStatsRecordValue(parent: parent)

        let fetchRequest = StatsRecord.fetchRequest(for: .lastPostInsight)

        let result = try! mainContext.fetch(fetchRequest)

        XCTAssertEqual(result.count, 1)
        XCTAssertNotNil((result.first!.values!.firstObject! as! LastPostStatsRecordValue).statsRecord)
    }

    func testInsertingSingleValueWorks() {
        mainContext.reset()

        let parent = createStatsRecord(in: mainContext, type: .lastPostInsight, date: Date())
        createLastPostStatsRecordValue(parent: parent)

        XCTAssertNoThrow(try mainContext.save())
    }

    func testInsertingMultipleFails() {
        mainContext.reset()

        let parent = createStatsRecord(in: mainContext, type: .lastPostInsight, date: Date())
        createLastPostStatsRecordValue(parent: parent)
        createLastPostStatsRecordValue(parent: parent)
        createLastPostStatsRecordValue(parent: parent)

        XCTAssertThrowsError(try mainContext.save()) { error in
            // the error is being bubbled up trough Obj-C Core Data innards, which means we can't just compare the enums.
            let thrownErrorAsNSError = error as NSError
            let expectedErrorAsNSErrror = StatsCoreDataValidationError.singleEntryTypeViolation as NSError

            let underlyingErrors = thrownErrorAsNSError.userInfo[NSDetailedErrorsKey] as! [NSError]

            XCTAssertEqual(underlyingErrors.count, 3, "should be as many as objects being attempted to insert")
            XCTAssertEqual(underlyingErrors.first!.domain, expectedErrorAsNSErrror.domain)
            XCTAssertEqual(underlyingErrors.first!.code, expectedErrorAsNSErrror.code)
            XCTAssert(true)
        }
    }

    // MARK: - LastPost specific posts

    func testURLConversionWorks() {
        let parent = createStatsRecord(in: mainContext, type: .lastPostInsight, date: Date())

        let recordValue = createLastPostStatsRecordValue(parent: parent)
        recordValue.urlString = "https://wordpress.com"

        let fetchRequest = StatsRecord.fetchRequest(for: .lastPostInsight)
        let result = try! mainContext.fetch(fetchRequest)

        let fetchedValue = result.first!.values!.firstObject as! LastPostStatsRecordValue
        XCTAssertNotNil(fetchedValue.url)
    }

    func testCoreDataConversion() {
        let date = Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2018, month: 1, day: 1))!

        let insight = StatsLastPostInsight(title: "test",
                                           url: URL(string: "google.com")!,
                                           publishedDate: date,
                                           likesCount: 1,
                                           commentsCount: 2,
                                           viewsCount: 3,
                                           postID: 4)

        let blog = defaultBlog

        _ = StatsRecord.record(from: insight, for: blog)

        XCTAssertNoThrow(try mainContext.save())

        let fetchRequest = StatsRecord.fetchRequest(for: .lastPostInsight)
        let result = try! mainContext.fetch(fetchRequest)
        let statsRecord = result.first!

        XCTAssertEqual(statsRecord.blog, blog)
        XCTAssertEqual(statsRecord.period, StatsRecordPeriodType.notApplicable.rawValue)

        let castedResults = statsRecord.values?.array.first! as! LastPostStatsRecordValue

        XCTAssertEqual(castedResults.title, "test")
        XCTAssertEqual(castedResults.publishedDate, date as NSDate)
        XCTAssertEqual(castedResults.likesCount, 1)
        XCTAssertEqual(castedResults.commentsCount, 2)
        XCTAssertEqual(castedResults.viewsCount, 3)
        XCTAssertEqual(castedResults.url, URL(string: "google.com") )
    }

    @discardableResult func createLastPostStatsRecordValue(parent: StatsRecord) -> LastPostStatsRecordValue {
        let record = LastPostStatsRecordValue(parent: parent)
        record.publishedDate = Date() as NSDate
        record.title = ""
        record.postID = 9001
        return record
    }

}
