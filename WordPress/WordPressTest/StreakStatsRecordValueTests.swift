@testable import WordPress
@testable import WordPressKit


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
        let parent = createStatsRecord(in: mainContext, type: .streakInsight, date: Date())
        let streakInsight = StreakInsightStatsRecordValue(parent: parent)
        streakInsight.longestStreakLength = 9001

        let now = Date()

        let streakValue1 = StreakStatsRecordValue(context: mainContext)
        streakValue1.postCount = 9001
        streakValue1.date = now as NSDate

        let weekAgo = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -7, to: now)

        let streakValue2 = StreakStatsRecordValue(context: mainContext)
        streakValue2.postCount = 9002
        streakValue2.date = weekAgo! as NSDate

        streakInsight.addToStreakData(NSOrderedSet(array: [streakValue1, streakValue2]))

        let fr = StatsRecord.fetchRequest(for: .streakInsight)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)

        let firstItem = results.first?.values?.firstObject! as? StreakInsightStatsRecordValue

        XCTAssertEqual(firstItem?.streakData?.count, 2)

        let firstValue = firstItem?.streakData?.firstObject! as! StreakStatsRecordValue
        XCTAssertNotNil(firstValue)

        XCTAssertEqual(firstValue.postCount, streakValue1.postCount)

        let secondValue = firstItem?.streakData?[1] as! StreakStatsRecordValue
        XCTAssertNotNil(secondValue)

        XCTAssertEqual(secondValue.postCount, streakValue2.postCount)
    }

    func testCoreDataConversion() {
        let now = Date()
        let weekAgo = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -7, to: now)

        let postingEventToday = PostingStreakEvent(date: now, postCount: 2)
        let postingEventWeekAgo = PostingStreakEvent(date: weekAgo!, postCount: 16)


        let streakInsight = StatsPostingStreakInsight(currentStreakStart: now,
                                                      currentStreakEnd: now,
                                                      currentStreakLength: 1,
                                                      longestStreakStart: weekAgo!,
                                                      longestStreakEnd: weekAgo!,
                                                      longestStreakLength: 15,
                                                      postingEvents: [postingEventWeekAgo, postingEventToday])

        let blog = defaultBlog

        _ = StatsRecord.record(from: streakInsight, for: blog)

        XCTAssertNoThrow(try mainContext.save())

        let fetchRequest = StatsRecord.fetchRequest(for: .streakInsight)

        let result = try! mainContext.fetch(fetchRequest)
        let statsRecord = result.first!

        XCTAssertEqual(statsRecord.blog, blog)
        XCTAssertEqual(statsRecord.period, StatsRecordPeriodType.notApplicable.rawValue)

        let castedResults = statsRecord.values?.array as! [StreakInsightStatsRecordValue]

        XCTAssertEqual(castedResults.count, 1)

        let insight = castedResults.first!

        XCTAssertEqual(insight.currentStreakStart, now as NSDate)
        XCTAssertEqual(insight.currentStreakEnd, now as NSDate)
        XCTAssertEqual(insight.currentStreakLength, 1)
        XCTAssertEqual(insight.longestStreakStart, weekAgo! as NSDate)
        XCTAssertEqual(insight.longestStreakEnd, weekAgo! as NSDate)
        XCTAssertEqual(insight.longestStreakLength, 15)

        XCTAssertEqual(insight.streakData?.count, 2)

        let firstData = insight.streakData?.firstObject as? StreakStatsRecordValue
        let secondData = insight.streakData?[1] as? StreakStatsRecordValue

        XCTAssertNotNil(firstData)
        XCTAssertNotNil(secondData)

        XCTAssertEqual(firstData?.postCount, 16)
        XCTAssertEqual(firstData?.date, weekAgo! as NSDate)

        XCTAssertEqual(secondData?.postCount, 2)
        XCTAssertEqual(secondData?.date, now as NSDate)
    }

}
