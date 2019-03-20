@testable import WordPress
@testable import WordPressKit

class FollowersStatsRecordValueTests: StatsTestCase {

    func testCreation() {
        let parent = createStatsRecord(in: mainContext, type: .followers, date: Date())

        let follower = FollowersStatsRecordValue(parent: parent)
        follower.name = "test"
        follower.type = FollowersStatsType.dotCom.rawValue

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .followers)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let followerRecord = results.first?.values?.firstObject! as! FollowersStatsRecordValue

        XCTAssertEqual(followerRecord.name, follower.name)
        XCTAssertEqual(followerRecord.type, follower.type)
    }

    func testTypeValidation() {
        let parent = createStatsRecord(in: mainContext, type: .followers, date: Date())

        let follower = FollowersStatsRecordValue(parent: parent)
        follower.name = "test"
        follower.type = 9001

        XCTAssertThrowsError(try mainContext.save()) { error in
            XCTAssertEqual(error._domain, StatsCoreDataValidationError.invalidEnumValue._domain)
            XCTAssertEqual(error._code, StatsCoreDataValidationError.invalidEnumValue._code)
        }
    }

    func testMultipleFollowers() {
        let parent = createStatsRecord(in: mainContext, type: .followers, date: Date())

        let follower1 = FollowersStatsRecordValue(parent: parent)
        follower1.name = "email"
        follower1.type = FollowersStatsType.email.rawValue

        let follower2 = FollowersStatsRecordValue(parent: parent)
        follower2.name = "dotcom"
        follower2.type = FollowersStatsType.dotCom.rawValue

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .followers)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 2)

        let followers = results.first?.values?.array as! [FollowersStatsRecordValue]

        let emailFollowers = followers.filter { $0.type == FollowersStatsType.email.rawValue }
        let dotComFollowers = followers.filter { $0.type == FollowersStatsType.dotCom.rawValue }

        XCTAssertEqual(emailFollowers.count, 1)
        XCTAssertEqual(dotComFollowers.count, 1)

        XCTAssertEqual(emailFollowers.first!.name, follower1.name)
        XCTAssertEqual(dotComFollowers.first!.name, follower2.name)
    }

    func testURLConversionWorks() {
        let parent = createStatsRecord(in: mainContext, type: .followers, date: Date())

        let follower = FollowersStatsRecordValue(parent: parent)
        follower.name = "Carol Mark"
        follower.type = FollowersStatsType.email.rawValue
        follower.avatarURLString = "www.wordpress.com"

        XCTAssertNoThrow(try mainContext.save())

        let fetchRequest = StatsRecord.fetchRequest(for: .followers)
        let result = try! mainContext.fetch(fetchRequest)

        let fetchedValue = result.first!.values!.firstObject as! FollowersStatsRecordValue
        XCTAssertNotNil(fetchedValue.avatarURL)
    }

    func testCoreDataConversion() {
        let follower1 = StatsFollower(name: "Carol", subscribedDate: Date(), avatarURL: nil)
        let follower2 = StatsFollower(name: "Mark", subscribedDate: Date(), avatarURL: nil)

        let dotComInsight = StatsDotComFollowersInsight(dotComFollowersCount: 1, topDotComFollowers: [follower1])
        let mailInsight = StatsEmailFollowersInsight(emailFollowersCount: 2, topEmailFollowers: [follower1, follower2])

        let blog = defaultBlog

        _ = StatsRecord.record(from: mailInsight, for: blog)
        _ = StatsRecord.record(from: dotComInsight, for: blog)
        _ = StatsRecord.record(from: mailInsight, for: blog)
        _ = StatsRecord.record(from: dotComInsight, for: blog)
        // this is duplicated on purpose, to make sure we're handling deleting of old/irrelevant data correctly.

        XCTAssertNoThrow(try mainContext.save())

        let fetchRequest = StatsRecord.fetchRequest(for: .followers)

        let result = try! mainContext.fetch(fetchRequest)
        let statsRecord = result.first!

        XCTAssertEqual(statsRecord.blog, blog)
        XCTAssertEqual(statsRecord.period, StatsRecordPeriodType.notApplicable.rawValue)

        let countResults = statsRecord.values?.filter { $0 is FollowersCountStatsRecordValue } as? [FollowersCountStatsRecordValue]
        let castedResults = statsRecord.values?.filter { $0 is FollowersStatsRecordValue } as? [FollowersStatsRecordValue]

        XCTAssertEqual(countResults?.count, 2)
        XCTAssertEqual(castedResults?.count, 3)

        let mailCount = countResults?.first { $0.type == FollowersStatsType.email.rawValue }
        XCTAssertNotNil(mailCount)
        XCTAssertEqual(mailCount?.count, 2)

        let dotComCount = countResults?.first { $0.type == FollowersStatsType.dotCom.rawValue }
        XCTAssertNotNil(dotComCount)
        XCTAssertEqual(dotComCount?.count, 1)

        let mailFollowers = castedResults?.filter { $0.type == FollowersStatsType.email.rawValue }
        let dotComFollowers = castedResults?.filter { $0.type == FollowersStatsType.dotCom.rawValue }

        XCTAssertEqual(mailFollowers?.count, 2)
        XCTAssertEqual(dotComFollowers?.count, 1)

        XCTAssertEqual(dotComFollowers?.first!.name, "Carol")

    }
}
