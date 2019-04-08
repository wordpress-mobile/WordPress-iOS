@testable import WordPress
class ReferrerStatsRecordValueTests: StatsTestCase {

    func testCreation() {
        let parent = createStatsRecord(in: mainContext, type: .referrers, period: .week, date: Date())

        let referrer = ReferrerStatsRecordValue(parent: parent)
        referrer.label = "test"
        referrer.viewsCount = 9001

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .referrers, on: Date(), periodType: .week)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let fetchedReferrer = results.first?.values?.firstObject! as! ReferrerStatsRecordValue

        XCTAssertEqual(fetchedReferrer.label, referrer.label)
        XCTAssertEqual(fetchedReferrer.viewsCount, referrer.viewsCount)
    }

    func testChildrenRelationships() {
        let parent = createStatsRecord(in: mainContext, type: .referrers, period: .week, date: Date())

        let referer = ReferrerStatsRecordValue(parent: parent)
        referer.label = "parent"
        referer.viewsCount = 5000

        let child = ReferrerStatsRecordValue(context: mainContext)
        child.label = "child"
        child.viewsCount = 4000

        let child2 = ReferrerStatsRecordValue(context: mainContext)
        child2.label = "child2"
        child2.viewsCount = 1

        referer.addToChildren([child, child2])

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .referrers, on: Date(), periodType: .week)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let fetchedReferer = results.first?.values?.firstObject! as! ReferrerStatsRecordValue

        XCTAssertEqual(fetchedReferer.label, referer.label)

        let children = fetchedReferer.children?.array as? [ReferrerStatsRecordValue]

        XCTAssertNotNil(children)
        XCTAssertEqual(children!.count, 2)
        XCTAssertEqual(children!.first!.label, child.label)
        XCTAssertEqual(children![1].label, child2.label)

        XCTAssertEqual(9001, fetchedReferer.viewsCount + children!.first!.viewsCount + children![1].viewsCount)
    }


    func testURLConversionWorks() {
        let parent = createStatsRecord(in: mainContext, type: .referrers, period: .week, date: Date())

        let referer = ReferrerStatsRecordValue(parent: parent)
        referer.label = "test"
        referer.viewsCount = 5000
        referer.urlString = "www.wordpress.com"

        parent.addToValues(referer)

        XCTAssertNoThrow(try mainContext.save())

        let fetchRequest = StatsRecord.fetchRequest(for: .referrers, on: Date(), periodType: .week)
        let result = try! mainContext.fetch(fetchRequest)

        let fetchedValue = result.first!.values!.firstObject as! ReferrerStatsRecordValue
        XCTAssertNotNil(fetchedValue.referrerURL)
    }

    func testIconURLConversionWorks() {
        let parent = createStatsRecord(in: mainContext, type: .referrers, period: .week, date: Date())

        let referer = ReferrerStatsRecordValue(parent: parent)
        referer.label = "test"
        referer.viewsCount = 5000
        referer.iconURLString = "www.wordpress.com"

        parent.addToValues(referer)

        XCTAssertNoThrow(try mainContext.save())

        let fetchRequest = StatsRecord.fetchRequest(for: .referrers, on: Date(), periodType: .week)
        let result = try! mainContext.fetch(fetchRequest)

        let fetchedValue = result.first!.values!.firstObject as! ReferrerStatsRecordValue
        XCTAssertNotNil(fetchedValue.iconURL)
    }

}
