@testable import WordPress

class TopCommentedPostStatsRecordValueTests: StatsTestCase {

    func testMultipleTopPosts() {
        let parent = createStatsRecord(in: mainContext, type: .topCommentedPosts, date: Date())

        let post1 = TopCommentedPostStatsRecordValue(parent: parent)
        post1.title = "My Great Post Number 1"
        post1.commentCount = 9001

        let post2 = TopCommentedPostStatsRecordValue(parent: parent)
        post2.title = "My Great Post Number 2"
        post2.commentCount = 9002

        let fr = StatsRecord.fetchRequest(for: .topCommentedPosts)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 2)

        let posts = results.first?.values?.array as! [TopCommentedPostStatsRecordValue]

        let fetchedPost1 = posts.filter { $0.commentCount == 9001 }
        let fetchedPost2 = posts.filter { $0.commentCount == 9002 }

        XCTAssertEqual(fetchedPost1.count, 1)
        XCTAssertEqual(fetchedPost2.count, 1)

        XCTAssertEqual(fetchedPost1.first!.title, post1.title)
        XCTAssertEqual(fetchedPost2.first!.title, post2.title)
    }

    func testURLConversionWorks() {
        let parent = createStatsRecord(in: mainContext, type: .topCommentedPosts, date: Date())

        let post1 = TopCommentedPostStatsRecordValue(parent: parent)
        post1.postURLString = "wordpress.com"

        let fetchRequest = StatsRecord.fetchRequest(for: .topCommentedPosts)
        let result = try! mainContext.fetch(fetchRequest)

        let fetchedValue = result.first!.values!.firstObject as! TopCommentedPostStatsRecordValue
        XCTAssertNotNil(fetchedValue.postURL)
    }

}
