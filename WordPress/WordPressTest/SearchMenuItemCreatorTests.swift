import XCTest
@testable import WordPress
@testable import Gridicons

final class SearchMenuItemCreatorTests: XCTestCase {
    private var creator: SearchMenuItemCreator?

    private struct TestConstants {
        static let title = NSLocalizedString("Search", comment: "Search")
        static let icon = UIImage.gridicon(.search)
    }

    override func setUp() {
        super.setUp()
        creator = SearchMenuItemCreator()
    }

    override func tearDown() {
        creator = nil
        super.tearDown()
    }

    func testItemCreatorReturnsItemWithExpectedTitle() {
        let item = creator!.menuItem()

        XCTAssertEqual(item.title, String(format: TestConstants.title))
    }

    func testItemCreatorReturnsItemWithExpectedIcon() {
        let item = creator!.menuItem()

        XCTAssertEqual(item.icon, TestConstants.icon)
    }
}
