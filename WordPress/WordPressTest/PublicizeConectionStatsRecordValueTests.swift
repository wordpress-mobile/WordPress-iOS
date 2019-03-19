@testable import WordPress
@testable import WordPressKit

class PublicizeConectionStatsRecordValueTests: StatsTestCase {
    func testMultiplePublicizeServices() {
        let parent = createStatsRecord(in: mainContext, type: .publicizeConnection, date: Date())

        let connection1 = PublicizeConnectionStatsRecordValue(parent: parent)
        connection1.name = "Social Network Beginning With T"
        connection1.followersCount = 9001

        let connection2 = PublicizeConnectionStatsRecordValue(parent: parent)
        connection2.name = "Social Network Beginning With F"
        connection2.followersCount = 1

        let fr = StatsRecord.fetchRequest(for: .publicizeConnection)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 2)

        let followers = results.first?.values?.array as! [PublicizeConnectionStatsRecordValue]

        let t = followers.filter { $0.followersCount == 9001 }
        let f = followers.filter { $0.followersCount == 1 }

        XCTAssertEqual(t.count, 1)
        XCTAssertEqual(f.count, 1)

        XCTAssertEqual(t.first!.name, connection1.name)
        XCTAssertEqual(f.first!.name, connection2.name)
    }

    func testURLConversionWorks() {
        let parent = createStatsRecord(in: mainContext, type: .publicizeConnection, date: Date())

        let connection1 = PublicizeConnectionStatsRecordValue(parent: parent)
        connection1.name = "Dead Social Network Ending With A Plus"
        connection1.followersCount = 0
        connection1.iconURLString = "www.wordpress.com"

        let fetchRequest = StatsRecord.fetchRequest(for: .publicizeConnection)
        let result = try! mainContext.fetch(fetchRequest)

        let fetchedValue = result.first!.values!.firstObject as! PublicizeConnectionStatsRecordValue
        XCTAssertNotNil(fetchedValue.iconURL)
    }

    func testCoreDataConversion() {
        let connection1 = StatsPublicizeService(name: "test 1",
                                                followers: 9001,
                                                iconURL: URL(string: "https://wordpress.com"))

        let connection2 = StatsPublicizeService(name: "bird site",
                                                followers: 0,
                                                iconURL: nil)

        let insight = StatsPublicizeInsight(publicizeServices: [connection1, connection2])

        let blog = defaultBlog

        _ = StatsRecord.record(from: insight, for: blog)

        XCTAssertNoThrow(try mainContext.save())

        let fetchRequest = StatsRecord.fetchRequest(for: .publicizeConnection)

        let result = try! mainContext.fetch(fetchRequest)
        let statsRecord = result.first!

        XCTAssertEqual(statsRecord.blog, blog)
        XCTAssertEqual(statsRecord.period, StatsRecordPeriodType.notApplicable.rawValue)

        let castedResults = statsRecord.values?.array as! [PublicizeConnectionStatsRecordValue]

        XCTAssertEqual(castedResults.count, 2)

        let firstResult = castedResults.first
        let secondResult = castedResults[1]

        XCTAssertNotNil(firstResult)
        XCTAssertNotNil(secondResult)

        XCTAssertEqual(firstResult?.name, "test 1")
        XCTAssertEqual(firstResult?.followersCount, 9001)
        XCTAssertEqual(firstResult?.iconURL, URL(string: "https://wordpress.com"))


        XCTAssertEqual(secondResult.name, "bird site")
        XCTAssertEqual(secondResult.followersCount, 0)
        XCTAssertNil(secondResult.iconURL)
    }
}
