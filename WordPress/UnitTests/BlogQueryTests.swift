import XCTest
@testable import WordPress

class BlogQueryTests: CoreDataTestCase {

    override func setUp() {
        super.setUp()

        BlogBuilder(mainContext).with(blogID: 1).withAnAccount(username: "BlogQuery").with(visible: true).build()
        BlogBuilder(mainContext).with(blogID: 2).withAnAccount().with(visible: false).build()
        BlogBuilder(mainContext).with(blogID: 3).with(visible: false).build()
    }

    func testQueryByBlogID() throws {
        let query = BlogQuery().blogID(3)
        XCTAssertEqual(query.count(in: mainContext), 1)
        XCTAssertEqual(try query.blog(in: mainContext)?.blogID, 3)
    }

    func testQueryByUsername() throws {
        let query = BlogQuery().dotComAccountUsername("BlogQuery")
        XCTAssertEqual(query.count(in: mainContext), 1)
        XCTAssertEqual(try query.blog(in: mainContext)?.account?.username, "BlogQuery")
    }

    func testQueryByHostname() {
        let query = BlogQuery().hostname(containing: "example.com")
        XCTAssertEqual(query.count(in: mainContext), 3)
    }

    func testQueryByVisible() {
        XCTAssertEqual(BlogQuery().visible(true).count(in: mainContext), 1)
        XCTAssertEqual(BlogQuery().visible(false).count(in: mainContext), 2)
    }

    func testQueryByHost() {
        XCTAssertEqual(BlogQuery().hostedByWPCom(true).count(in: mainContext), 2)
        XCTAssertEqual(BlogQuery().hostedByWPCom(false).count(in: mainContext), 1)
    }

    func testQueryCombinations() {
        XCTAssertEqual(BlogQuery().visible(false).hostedByWPCom(false).count(in: mainContext), 1)
    }

}
