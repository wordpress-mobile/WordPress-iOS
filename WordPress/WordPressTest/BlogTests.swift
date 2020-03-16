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
}
