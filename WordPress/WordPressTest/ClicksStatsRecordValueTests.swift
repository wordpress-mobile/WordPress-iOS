@testable import WordPress

class ClicksStatsRecordValueTests: StatsTestCase {

    func testCreation() {
        let parent = createStatsRecord(in: mainContext, type: .clicks, period: .month, date: Date())

        let clicks = ClicksStatsRecordValue(parent: parent)
        clicks.label = "test"
        clicks.clicksCount = 9001

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .clicks, on: Date(), periodType: .month)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let fetchedClicks = results.first?.values?.firstObject! as! ClicksStatsRecordValue

        XCTAssertEqual(fetchedClicks.label, clicks.label)
        XCTAssertEqual(fetchedClicks.clicksCount, clicks.clicksCount)
    }

    func testChildrenRelationships() {
        let parent = createStatsRecord(in: mainContext, type: .clicks, period: .month, date: Date())

        let clicks = ClicksStatsRecordValue(parent: parent)
        clicks.label = "parent"
        clicks.clicksCount = 5000

        let child = ClicksStatsRecordValue(context: mainContext)
        child.label = "child"
        child.clicksCount = 4000

        let child2 = ClicksStatsRecordValue(context: mainContext)
        child2.label = "child2"
        child2.clicksCount = 1

        clicks.addToChildren([child, child2])

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .clicks, on: Date(), periodType: .month)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let fetchedClicks = results.first?.values?.firstObject! as! ClicksStatsRecordValue

        XCTAssertEqual(fetchedClicks.label, clicks.label)

        let children = fetchedClicks.children?.array as? [ClicksStatsRecordValue]

        XCTAssertNotNil(children)
        XCTAssertEqual(children!.count, 2)
        XCTAssertEqual(children!.first!.label, child.label)
        XCTAssertEqual(children![1].label, child2.label)

        XCTAssertEqual(9001, fetchedClicks.clicksCount + children!.first!.clicksCount + children![1].clicksCount)
    }


    func testURLConversionWorks() {
        let parent = createStatsRecord(in: mainContext, type: .clicks, period: .month, date: Date())

        let tag = ClicksStatsRecordValue(parent: parent)
        tag.urlString = "www.wordpress.com"
        tag.clicksCount = 90001
        tag.label = "test"

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .clicks, on: Date(), periodType: .month)
        let result = try! mainContext.fetch(fr)

        let fetchedValue = result.first!.values!.firstObject as! ClicksStatsRecordValue
        XCTAssertNotNil(fetchedValue.clickedURL)
    }

}
