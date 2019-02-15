@testable import WordPress


class StreakStatsRecordValueTests: StatsTestCase {

    func testInsightCreation() {
        let parent = createStatsRecord(in: mainContext, type: .streakInsight, date: Date())

        let streakInsight = StreakInsightStatsRecordValue(parent: parent)
        streakInsight.longestStreakLength = 9001

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .streakInsight)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let streak = results.first?.values?.firstObject! as! StreakInsightStatsRecordValue

        XCTAssertEqual(streak.longestStreakLength, streakInsight.longestStreakLength)
    }

    func testStreakCreation() {
        let now = Date()

        let streakItem1 = createStatsRecord(in: mainContext, type: .postingStreak, date: now)
        let streakValue1 = StreakStatsRecordValue(parent: streakItem1)
        streakValue1.postCount = 9001

        let weekAgo = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -7, to: now)

        let streakItem2 = createStatsRecord(in: mainContext, type: .postingStreak, date: weekAgo!)
        let streakValue2 = StreakStatsRecordValue(parent: streakItem2)
        streakValue2.postCount = 9002

        let fr = StatsRecord.fetchRequest(for: .postingStreak)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)

        let firstItem = results.first!
        XCTAssertEqual(firstItem.values!.count, 1)

        let firstValue = firstItem.values?.firstObject! as! StreakStatsRecordValue
        XCTAssertNotNil(firstValue)

        XCTAssertEqual(firstValue.postCount, streakValue1.postCount)

        // this might get potentially flaky for... seven seconds around midnight each day.
        // hopefully this won't be a problem, but I wanted to test that fetching by dates
        // that aren't exact matches still works.
        let fewSecondsAfterAWeekAgo = Calendar.autoupdatingCurrent.date(byAdding: .second, value: 7, to: weekAgo!)!

        let fr2 = StatsRecord.fetchRequest(for: .postingStreak, on: fewSecondsAfterAWeekAgo)
        let results2 = try! mainContext.fetch(fr2)

        XCTAssertEqual(results2.count, 1)

        let secondItem = results2.first!
        XCTAssertEqual(secondItem.values!.count, 1)

        let secondValue = secondItem.values?.firstObject! as! StreakStatsRecordValue
        XCTAssertNotNil(secondValue)

        XCTAssertEqual(secondValue.postCount, streakValue2.postCount)
    }

}
