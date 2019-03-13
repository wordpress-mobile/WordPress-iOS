@testable import WordPress

class TopCommentedPostStatsRecordValueTests: StatsTestCase {

    func testMultipleTopPosts() {
        let parent = createStatsRecord(in: mainContext, type: .commentInsight, date: Date())

        let post1 = TopCommentedPostStatsRecordValue(parent: parent)
        post1.title = "My Great Post Number 1"
        post1.commentCount = 9001
        post1.postURLString = "n/a"

        let post2 = TopCommentedPostStatsRecordValue(parent: parent)
        post2.title = "My Great Post Number 2"
        post2.commentCount = 9002
        post2.postURLString = "n/a"

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .commentInsight)

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

    func testPostURLConversionWorks() {
        let parent = createStatsRecord(in: mainContext, type: .commentInsight, date: Date())

        let post1 = TopCommentedPostStatsRecordValue(parent: parent)
        post1.postURLString = "wordpress.com"
        post1.postURLString = "n/a"
        post1.commentCount = 6

        XCTAssertNoThrow(try mainContext.save())

        let fetchRequest = StatsRecord.fetchRequest(for: .commentInsight)
        let result = try! mainContext.fetch(fetchRequest)

        let fetchedValue = result.first!.values!.firstObject as! TopCommentedPostStatsRecordValue
        XCTAssertNotNil(fetchedValue.postURL)
    }

    func testMultipleTopAuthors() {
        let parent = createStatsRecord(in: mainContext, type: .commentInsight, date: Date())

        let author1 = TopCommentsAuthorStatsRecordValue(parent: parent)
        author1.name = "Prolific Commenter Named Carl"
        author1.commentCount = 9001

        let author2 = TopCommentsAuthorStatsRecordValue(parent: parent)
        author2.name = "Prolific Commenter Named Mark"
        author2.commentCount = 9002

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .commentInsight)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 2)

        let authors = results.first?.values?.array as! [TopCommentsAuthorStatsRecordValue]

        let fetchedAuthor1 = authors.filter { $0.commentCount == 9001 }
        let fetchedAuthor2 = authors.filter { $0.commentCount == 9002 }

        XCTAssertEqual(fetchedAuthor1.count, 1)
        XCTAssertEqual(fetchedAuthor2.count, 1)

        XCTAssertEqual(fetchedAuthor1.first!.name, author1.name)
        XCTAssertEqual(fetchedAuthor2.first!.name, author2.name)
    }

    func testAuthorURLConversionWorks() {
        let parent = createStatsRecord(in: mainContext, type: .commentInsight, date: Date())

        let author1 = TopCommentsAuthorStatsRecordValue(parent: parent)
        author1.avatarURLString = "www.wp.com"
        author1.commentCount = 9001

        XCTAssertNoThrow(try mainContext.save())

        let fetchRequest = StatsRecord.fetchRequest(for: .commentInsight)
        let result = try! mainContext.fetch(fetchRequest)

        let fetchedValue = result.first!.values!.firstObject as! TopCommentsAuthorStatsRecordValue
        XCTAssertNotNil(fetchedValue.avatarURL)
    }

    func testMultipleValueTypes() {
        let parent = createStatsRecord(in: mainContext, type: .commentInsight, date: Date())

        let post = TopCommentedPostStatsRecordValue(parent: parent)
        post.title = "My Great Post Number 1"
        post.commentCount = 9001
        post.postURLString = "n/a"

        let author = TopCommentsAuthorStatsRecordValue(parent: parent)
        author.name = "Prolific Commenter Named Carl"
        author.commentCount = 9002

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .commentInsight)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 2)

        let authors = results.first!.values?.filter { $0 is TopCommentsAuthorStatsRecordValue } as? [TopCommentsAuthorStatsRecordValue]
        let posts = results.first!.values?.filter { $0 is TopCommentedPostStatsRecordValue } as? [TopCommentedPostStatsRecordValue]

        XCTAssertEqual(authors?.count, 1)
        XCTAssertEqual(posts?.count, 1)

        XCTAssertEqual(authors?.first?.name, "Prolific Commenter Named Carl")
        XCTAssertEqual(authors?.first?.commentCount, 9002)

        XCTAssertEqual(posts?.first?.title, "My Great Post Number 1")
        XCTAssertEqual(posts?.first?.commentCount, 9001)

    }

    func testCoreDataConversion() {
        XCTAssertTrue(true)
    }

}
