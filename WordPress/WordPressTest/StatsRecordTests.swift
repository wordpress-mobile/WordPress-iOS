import XCTest
import CoreData
@testable import WordPress

class StatsRecordTests: XCTestCase {

    fileprivate var manager: TestContextManager!

    override func setUp() {
        manager = TestContextManager()
    }

    var mainContext: NSManagedObjectContext {
        return manager.mainContext
    }

    override func tearDown() {
        mainContext.reset()
    }

    func testCreatingAndSaving() {
        createStatsRecord(in: mainContext, type: .blogStats, date: Date())
        createStatsRecord(in: mainContext, type: .blogStats, date: Date())
        createStatsRecord(in: mainContext, type: .blogStats, date: Date())

        do {
            try mainContext.save()
            XCTAssert(true)
        } catch {
            XCTAssert(false, "error while saving, should never be true")
        }
    }

    func testDateValidationWorks() {
        let record = createStatsRecord(in: mainContext, type: .blogStats, date: Date())
        record.date = nil

        do {
            try mainContext.save()
            XCTAssert(false, "this should throw a validation error")
        } catch {
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

        do {
            try mainContext.save()
            XCTAssert(true)
        } catch {
            XCTAssert(false, "error while saving, should never be true")
        }
    }

    func testSingleElementValidation() {
        createStatsRecord(in: mainContext, type: .allTimeStatsInsight, date: Date())
        createStatsRecord(in: mainContext, type: .allTimeStatsInsight, date: Date())
        createStatsRecord(in: mainContext, type: .allTimeStatsInsight, date: Date())
        createStatsRecord(in: mainContext, type: .allTimeStatsInsight, date: Date())
        createStatsRecord(in: mainContext, type: .allTimeStatsInsight, date: Date())

        do {
            try mainContext.save()
            XCTAssert(false, "this should never succeed and fail with validation warning")
        }
        catch {
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
        createStatsRecord(in: mainContext, type: .blogStats, date: Date())
        createStatsRecord(in: mainContext, type: .blogStats, date: Date())
        createStatsRecord(in: mainContext, type: .blogStats, date: Date())

        let fetchRequest = StatsRecord.fetchRequest(for: .blogStats)

        let allResults = try! mainContext.fetch(StatsRecord.fetchRequest())
        let results = try! mainContext.fetch(fetchRequest)

        XCTAssert(allResults.isEmpty == false)
        XCTAssert(results.count == 3)
    }

    func testFetchingProperTypeOnly() {
        createStatsRecord(in: mainContext, type: .blogStats, date: Date())
        createStatsRecord(in: mainContext, type: .lastPostInsight, date: Date())

        let fetchRequest = StatsRecord.fetchRequest(for: .blogStats)

        let results = try! mainContext.fetch(fetchRequest)

        XCTAssert(results.count == 1)
    }

    func testFetchingForYesterday() {
        let calendar = Calendar.autoupdatingCurrent
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        createStatsRecord(in: mainContext, type: .blogStats, date: yesterday)
        createStatsRecord(in: mainContext, type: .blogStats, date: yesterday)
        createStatsRecord(in: mainContext, type: .lastPostInsight, date: yesterday)
        createStatsRecord(in: mainContext, type: .blogStats, date: Date())
        createStatsRecord(in: mainContext, type: .blogStats, date: Date())

        let fetchRequest = StatsRecord.fetchRequest(for: .blogStats, on: yesterday)

        let results = try! mainContext.fetch(fetchRequest)

        XCTAssert(results.count == 2)
    }

    func testFetchingForAnywhereInADay() {
        let calendar = Calendar.autoupdatingCurrent
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        let yesterdayHourEarlier = calendar.date(byAdding: .hour, value: -1, to: yesterday)!
        let yesterdayHourLater = calendar.date(byAdding: .hour, value: 1, to: yesterday)!

        let yesterdayRange = calendar.dateInterval(of: .day, for: yesterday)!

        createStatsRecord(in: mainContext, type: .blogStats, date: yesterday)
        createStatsRecord(in: mainContext, type: .blogStats, date: yesterdayHourLater)
        createStatsRecord(in: mainContext, type: .blogStats, date: yesterdayHourEarlier)
        createStatsRecord(in: mainContext, type: .blogStats, date: yesterdayRange.start)
        createStatsRecord(in: mainContext, type: .blogStats, date: yesterdayRange.end)

        let fetchRequest = StatsRecord.fetchRequest(for: .blogStats, on: yesterday)

        let results = try! mainContext.fetch(fetchRequest)

        XCTAssert(results.count == 5)
    }
}
