import XCTest
@testable import WordPress

final class TrashCommentActionTests: XCTestCase {
    private class TestableTrashComment: TrashComment {
        let service = MockNotificationActionsService(managedObjectContext: TestContextManager.sharedInstance().mainContext)
        override var actionsService: NotificationActionsService? {
            return service
        }
    }

    private class MockNotificationActionsService: NotificationActionsService {
        override func deleteCommentWithBlock(_ block: ActionableObject, completion: ((Bool) -> Void)?) {
            completion?(true)
        }
    }

    private var action: TrashComment?

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        action = TestableTrashComment(on: Constants.initialStatus)
        makeNetworkAvailable()
    }

    override func tearDown() {
        action = nil
        makeNetworkUnavailable()
        super.tearDown()
    }

    func testStatusPassedInInitialiserIsPreserved() {
        XCTAssertEqual(action?.on, Constants.initialStatus)
    }

    func testDefaultTitleIsExpected() {
        XCTAssertEqual(action?.icon?.titleLabel?.text, TrashComment.title)
    }

    func testDefaultAccessibilityLabelIsExpected() {
        XCTAssertEqual(action?.icon?.accessibilityLabel, TrashComment.title)
    }

    func testDefaultAccessibilityHintIsExpected() {
        XCTAssertEqual(action?.icon?.accessibilityHint, TrashComment.hint)
    }

    func testExecuteCallsTrash() {
        action?.on = false

        var executionCompleted = false

        let context = ActionContext(block: MockActionableObject(), content: "content") { (request, success) in
            executionCompleted = true
        }

        action?.execute(context: context)

        XCTAssertTrue(executionCompleted)
    }
}
