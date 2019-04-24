@testable import WordPress
class TopViewedVideoStatsTests: StatsTestCase {

    func testCreation() {
        let parent = createStatsRecord(in: mainContext, type: .videos, period: .day, date: Date())

        let video = TopViewedVideoStatsRecordValue(parent: parent)
        video.playsCount = 900000001
        video.title = "Selfies — how to do em good???????"
        video.postID = 9001

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .videos, on: Date(), periodType: .day)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let fetchedVideo = results.first?.values?.firstObject! as! TopViewedVideoStatsRecordValue

        XCTAssertEqual(fetchedVideo.title, video.title)
        XCTAssertEqual(fetchedVideo.playsCount, video.playsCount)
        XCTAssertEqual(fetchedVideo.postID, video.postID)
    }

    func testURLConversionWorks() {
        let parent = createStatsRecord(in: mainContext, type: .videos, period: .day, date: Date())

        let video = TopViewedVideoStatsRecordValue(parent: parent)
        video.postURLString = "www.wordpress.com"
        video.postID = 9001

        XCTAssertNoThrow(try mainContext.save())

        let fetchRequest = StatsRecord.fetchRequest(for: .videos, on: Date(), periodType: .day)
        let result = try! mainContext.fetch(fetchRequest)

        let fetchedValue = result.first!.values!.firstObject as! TopViewedVideoStatsRecordValue
        XCTAssertNotNil(fetchedValue.postURL)
    }

}
