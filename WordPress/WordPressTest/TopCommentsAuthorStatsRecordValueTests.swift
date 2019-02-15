@testable import WordPress

class TopCommentsAuthorStatsRecordValueTests: StatsTestCase {

    func testMultipleTopAuthors() {
        let parent = createStatsRecord(in: mainContext, type: .topCommentAuthors, date: Date())

        let author1 = TopCommentsAuthorStatsRecordValue(parent: parent)
        author1.name = "Prolific Commenter Named Carl"
        author1.commentCount = 9001

        let author2 = TopCommentsAuthorStatsRecordValue(parent: parent)
        author2.name = "Prolific Commenter Named Mark"
        author2.commentCount = 9002

        let fr = StatsRecord.fetchRequest(for: .topCommentAuthors)

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

    func testURLConversionWorks() {
        let parent = createStatsRecord(in: mainContext, type: .topCommentAuthors, date: Date())

        let author1 = TopCommentsAuthorStatsRecordValue(parent: parent)
        author1.avatarURLString = "www.wp.com"

        let fetchRequest = StatsRecord.fetchRequest(for: .topCommentAuthors)
        let result = try! mainContext.fetch(fetchRequest)

        let fetchedValue = result.first!.values!.firstObject as! TopCommentsAuthorStatsRecordValue
        XCTAssertNotNil(fetchedValue.avatarURL)
    }

}
