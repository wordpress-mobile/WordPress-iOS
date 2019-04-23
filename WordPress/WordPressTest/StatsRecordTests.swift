@testable import WordPress

class StatsRecordTests: StatsTestCase {

    func testCreatingAndSaving() {
        createStatsRecord(in: mainContext, type: .blogVisitsSummary, period: .day, date: Date())
        createStatsRecord(in: mainContext, type: .blogVisitsSummary, period: .day, date: Date())
        createStatsRecord(in: mainContext, type: .blogVisitsSummary, period: .day, date: Date())

        XCTAssertNoThrow(try mainContext.save())
    }

    func testDateValidationWorks() {
        let record = createStatsRecord(in: mainContext, type: .blogVisitsSummary, date: Date())
        record.date = nil

        XCTAssertThrowsError(try mainContext.save()) { error in
            let thrownErrorAsNSError = error as NSError
            let expectedErrorAsNSErrror = StatsCoreDataValidationError.noDate as NSError

            XCTAssert(thrownErrorAsNSError.domain == expectedErrorAsNSErrror.domain)
            XCTAssert(thrownErrorAsNSError.code == expectedErrorAsNSErrror.code)
            XCTAssert(true)
        }
    }

    func testDateValidationSkippedForSingleEntryType() {
        let record = createStatsRecord(in: mainContext, type: .allTimeStatsInsight, date: Date())
        record.date = nil

        XCTAssertNoThrow(try mainContext.save())
    }

    func testSingleElementValidation() {
        createStatsRecord(in: mainContext, type: .allTimeStatsInsight, date: Date())
        createStatsRecord(in: mainContext, type: .allTimeStatsInsight, date: Date())
        createStatsRecord(in: mainContext, type: .allTimeStatsInsight, date: Date())
        createStatsRecord(in: mainContext, type: .allTimeStatsInsight, date: Date())
        createStatsRecord(in: mainContext, type: .allTimeStatsInsight, date: Date())

        XCTAssertThrowsError(try mainContext.save()) { error in
            let thrownErrorAsNSError = error as NSError
            let expectedErrorAsNSErrror = StatsCoreDataValidationError.singleEntryTypeViolation as NSError

            let underlyingErrors = thrownErrorAsNSError.userInfo[NSDetailedErrorsKey] as! [NSError]

            XCTAssertEqual(underlyingErrors.count, 5, "should be as many as objects being attempted to insert")
            XCTAssertEqual(underlyingErrors.first!.domain, expectedErrorAsNSErrror.domain)
            XCTAssertEqual(underlyingErrors.first!.code, expectedErrorAsNSErrror.code)
            XCTAssert(true)
        }
    }

    func testFetchingForToday() {
        createStatsRecord(in: mainContext, type: .blogVisitsSummary, date: Date())
        createStatsRecord(in: mainContext, type: .blogVisitsSummary, date: Date())
        createStatsRecord(in: mainContext, type: .blogVisitsSummary, date: Date())

        let fetchRequest = StatsRecord.fetchRequest(for: .blogVisitsSummary)

        let allResults = try! mainContext.fetch(StatsRecord.fetchRequest())
        let results = try! mainContext.fetch(fetchRequest)

        XCTAssertEqual(allResults.isEmpty, false)
        XCTAssertEqual(results.count, 3)
    }

    func testFetchingProperTypeOnly() {
        createStatsRecord(in: mainContext, type: .blogVisitsSummary, date: Date())
        createStatsRecord(in: mainContext, type: .lastPostInsight, date: Date())

        let fetchRequest = StatsRecord.fetchRequest(for: .blogVisitsSummary)

        let results = try! mainContext.fetch(fetchRequest)

        XCTAssertEqual(results.count, 1)
    }

    func testFetchingForYesterday() {
        let calendar = Calendar.autoupdatingCurrent
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        createStatsRecord(in: mainContext, type: .blogVisitsSummary, date: yesterday)
        createStatsRecord(in: mainContext, type: .blogVisitsSummary, date: yesterday)
        createStatsRecord(in: mainContext, type: .lastPostInsight, date: yesterday)
        createStatsRecord(in: mainContext, type: .blogVisitsSummary, date: Date())
        createStatsRecord(in: mainContext, type: .blogVisitsSummary, date: Date())

        let fetchRequest = StatsRecord.fetchRequest(for: .blogVisitsSummary, on: yesterday)

        let results = try! mainContext.fetch(fetchRequest)

        XCTAssertEqual(results.count, 2)
    }
}
