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
        let query = CoreDataQuery<Blog>.default().blogID(3)
        XCTAssertEqual(query.count(in: mainContext), 1)
        XCTAssertEqual(try query.first(in: mainContext)?.blogID, 3)
    }

    func testQueryByUsername() throws {
        let query = CoreDataQuery<Blog>.default().username("BlogQuery")
        XCTAssertEqual(query.count(in: mainContext), 1)
        XCTAssertEqual(try query.first(in: mainContext)?.account?.username, "BlogQuery")
    }

    func testQueryByHostname() {
        let query = CoreDataQuery<Blog>.default().hostname(containing: "example.com")
        XCTAssertEqual(query.count(in: mainContext), 3)
    }

    func testQueryByVisible() {
        XCTAssertEqual(CoreDataQuery<Blog>.default().visible(true).count(in: mainContext), 1)
        XCTAssertEqual(CoreDataQuery<Blog>.default().visible(false).count(in: mainContext), 2)
    }

    func testQueryByHost() {
        XCTAssertEqual(CoreDataQuery<Blog>.default().hostedByWPCom(true).count(in: mainContext), 2)
        XCTAssertEqual(CoreDataQuery<Blog>.default().hostedByWPCom(false).count(in: mainContext), 1)
    }

    func testQueryCombinations() {
        XCTAssertEqual(CoreDataQuery<Blog>.default().visible(false).hostedByWPCom(false).count(in: mainContext), 1)
    }

}
