@testable import WordPress
class SearchResultsStatsRecordValueTests: StatsTestCase {

    func testSearchResultsCreation() {
        let now = Date()

        let searchItem1 = createStatsRecord(in: mainContext, type: .searchTerms, date: now)
        let searchValue1 = SearchResultsStatsRecordValue(parent: searchItem1)
        searchValue1.viewsCount = 9001

        let weekAgo = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -7, to: now)

        let searchItem2 = createStatsRecord(in: mainContext, type: .searchTerms, date: weekAgo!)
        let searchValue2 = SearchResultsStatsRecordValue(parent: searchItem2)
        searchValue2.viewsCount = 9002

        let fr = StatsRecord.fetchRequest(for: .searchTerms)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)

        let firstItem = results.first!
        XCTAssertEqual(firstItem.values!.count, 1)

        let firstValue = firstItem.values?.firstObject! as! SearchResultsStatsRecordValue
        XCTAssertNotNil(firstValue)

        XCTAssertEqual(firstValue.viewsCount, searchValue1.viewsCount)

        // this might get potentially flaky for... seven seconds around midnight each day.
        // hopefully this won't be a problem, but I wanted to test that fetching by dates
        // that aren't exact matches still works.
        let fewSecondsAfterAWeekAgo = Calendar.autoupdatingCurrent.date(byAdding: .second, value: 7, to: weekAgo!)!

        let fr2 = StatsRecord.fetchRequest(for: .searchTerms, on: fewSecondsAfterAWeekAgo)
        let results2 = try! mainContext.fetch(fr2)

        XCTAssertEqual(results2.count, 1)

        let secondItem = results2.first!
        XCTAssertEqual(secondItem.values!.count, 1)

        let secondValue = secondItem.values?.firstObject! as! SearchResultsStatsRecordValue
        XCTAssertNotNil(secondValue)

        XCTAssertEqual(secondValue.viewsCount, searchValue2.viewsCount)
    }


    func testSavingWithMagicValueWorks() {
        let now = Date()

        let searchItem = createStatsRecord(in: mainContext, type: .searchTerms, date: now)
        let searchValue = SearchResultsStatsRecordValue(parent: searchItem)
        searchValue.viewsCount = 9001
        searchValue.searchTerm = SearchResultsStatsRecordValue.unknownSearchTermString

        let fr = StatsRecord.fetchRequest(for: .searchTerms)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)

        let firstItem = results.first!
        XCTAssertEqual(firstItem.values!.count, 1)

        let firstValue = firstItem.values?.firstObject! as! SearchResultsStatsRecordValue
        XCTAssertNotNil(firstValue)

        XCTAssertEqual(firstValue.viewsCount, searchValue.viewsCount)
        XCTAssertEqual(firstValue.searchTerm, searchValue.searchTerm)

    }


}
