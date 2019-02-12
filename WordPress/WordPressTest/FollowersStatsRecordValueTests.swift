@testable import WordPress

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

}
