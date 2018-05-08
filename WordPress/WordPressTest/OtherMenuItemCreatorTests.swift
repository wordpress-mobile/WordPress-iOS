import XCTest
@testable import WordPress
@testable import Gridicons

final class OtherMenuItemCreatorTests: XCTestCase {
    private var testContextManager: TestContextManager?
    private var topic: ReaderAbstractTopic?
    private var creator: ReaderMenuItemCreator?

    private struct TestConstants {
        static let title = "Other"
    }

    override func setUp() {
        super.setUp()
        testContextManager = TestContextManager()
        topic = NSEntityDescription.insertNewObject(forEntityName: ReaderListTopic.classNameWithoutNamespaces(), into: ContextManager.sharedInstance().mainContext) as! ReaderListTopic
        topic!.title = TestConstants.title
        topic!.type = ReaderListTopic.TopicType

        creator = OtherMenuItemCreator()
    }

    override func tearDown() {
        ContextManager.overrideSharedInstance(nil)
        testContextManager = nil
        topic = nil
        creator = nil
        super.tearDown()
    }

    func testItemCreatorReturnsItemWithExpectedTitle() {
        let item = creator!.menuItem(with: topic!)

        XCTAssertEqual(item.title, TestConstants.title)
    }

    func testItemCreatorReturnsItemWithExpectedIcon() {
        let item = creator!.menuItem(with: topic!)

        XCTAssertNil(item.icon)
    }
}
