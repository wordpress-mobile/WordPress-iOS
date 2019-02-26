@testable import WordPress
class VisitsSummaryStatsRecordValueTests: StatsTestCase {

    func testCreation() {
        let parent = createStatsRecord(in: mainContext, type: .blogVisitsSummary, period: .week, date: Date())

        let visits = VisitsSummaryStatsRecordValue(parent: parent)
        visits.viewsCount = 1
        visits.visitorsCount = 2
        visits.likesCount = 3
        visits.commentsCount = 4

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .blogVisitsSummary)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let fetchedVisits = results.first?.values?.firstObject! as! VisitsSummaryStatsRecordValue

        XCTAssertEqual(fetchedVisits.viewsCount, visits.viewsCount)
        XCTAssertEqual(fetchedVisits.visitorsCount, visits.visitorsCount)
        XCTAssertEqual(fetchedVisits.likesCount, visits.likesCount)
        XCTAssertEqual(fetchedVisits.commentsCount, visits.commentsCount)
    }

}
