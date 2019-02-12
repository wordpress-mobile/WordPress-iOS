@testable import WordPress

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

    @discardableResult func createLastPostStatsRecordValue(parent: StatsRecord) -> LastPostStatsRecordValue {
        let record = LastPostStatsRecordValue(parent: parent)
        record.publishedDate = Date() as NSDate
        record.title = ""
        return record
    }

}
