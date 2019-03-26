@testable import WordPress

class TopViewedStatsTests: StatsTestCase {

    func testAuthorCreation() {
        let parent = createStatsRecord(in: mainContext, type: .topViewedAuthor, period: .year, date: Date())

        let author = TopViewedAuthorStatsRecordValue(parent: parent)
        author.viewsCount = 22
        author.name = "Saylor Twift"

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .topViewedAuthor, on: Date(), periodType: .year)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let fetchedAuthor = results.first?.values?.firstObject! as! TopViewedAuthorStatsRecordValue

        XCTAssertEqual(fetchedAuthor.name, author.name)
        XCTAssertEqual(fetchedAuthor.viewsCount, author.viewsCount)
    }

    func testPostCreation() {
        let parent = createStatsRecord(in: mainContext, type: .topViewedPost, period: .year, date: Date())

        let post = TopViewedPostStatsRecordValue(parent: parent)
        post.viewsCount = 1989
        post.title = "(blank space)"
        post.postID = 9001
        post.type = TopViewsPostType.unknown.rawValue

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .topViewedPost, on: Date(), periodType: .year)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let fetchedPost = results.first?.values?.firstObject! as! TopViewedPostStatsRecordValue

        XCTAssertEqual(fetchedPost.title, post.title)
        XCTAssertEqual(fetchedPost.viewsCount, post.viewsCount)
    }

    func testRelationshipCreation() {
        let parent = createStatsRecord(in: mainContext, type: .topViewedAuthor, period: .year, date: Date())

        let author = TopViewedAuthorStatsRecordValue(parent: parent)
        author.viewsCount = 22
        author.name = "Saylor Twift"

        let post = TopViewedPostStatsRecordValue(context: mainContext)
        post.viewsCount = 1989
        post.title = "(blank space)"
        post.postID = 9001
        post.type = TopViewsPostType.unknown.rawValue

        author.addToPosts(post)

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .topViewedAuthor, on: Date(), periodType: .year)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let fetchedAuthor = results.first?.values?.firstObject! as! TopViewedAuthorStatsRecordValue

        XCTAssertNotNil(fetchedAuthor.posts)
        XCTAssertEqual(fetchedAuthor.posts!.count, 1)
    }

}
