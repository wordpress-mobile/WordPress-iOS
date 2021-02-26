import CoreData
import XCTest
@testable import WordPress

final class BlogTests: XCTestCase {

    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        context = TestContextManager().mainContext
    }

    override func tearDown() {
        super.tearDown()
    }

    func testIsAtomic() {
        let blog = BlogBuilder(context)
            .with(atomic: true)
            .build()

        XCTAssertTrue(blog.isAtomic())
    }

    func testIsNotAtomic() {
        let blog = BlogBuilder(context)
            .with(atomic: false)
            .build()

        XCTAssertFalse(blog.isAtomic())
    }

    func testThatLookupByBlogIDWorks() throws {
        let blog = BlogBuilder(context).build()
        XCTAssertNotNil(blog.dotComID)
        XCTAssertNotNil(Blog.lookup(withID: blog.dotComID!, in: context))
    }

    func testThatLookupByBlogIDFailsForInvalidBlogID() throws {
        XCTAssertNil(Blog.lookup(withID: NSNumber(integerLiteral: 1), in: context))
    }

    func testThatLookupByBlogIDWorksForIntegerBlogID() throws {
        let blog = BlogBuilder(context).build()
        XCTAssertNotNil(blog.dotComID)
        XCTAssertNotNil(try Blog.lookup(withID: blog.dotComID!.intValue, in: context))
    }

    func testThatLookupByBlogIDFailsForInvalidIntegerBlogID() throws {
        XCTAssertNil(try Blog.lookup(withID: 1, in: context))
    }

    func testThatLookupBlogIDWorksForInt64BlogID() throws {
        let blog = BlogBuilder(context).build()
        XCTAssertNotNil(blog.dotComID)
        XCTAssertNotNil(try Blog.lookup(withID: blog.dotComID!.int64Value, in: context))
    }

    func testThatLookupByBlogIDFailsForInvalidInt64BlogID() throws {
        XCTAssertNil(try Blog.lookup(withID: Int64(1), in: context))
    }

}
