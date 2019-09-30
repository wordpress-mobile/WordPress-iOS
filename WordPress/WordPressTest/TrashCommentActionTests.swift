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
        override func deleteCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)?) {
            completion?(true)
        }
    }

    private var action: TrashComment?
    let utils = NotificationUtility()

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        utils.setUp()
        action = TestableTrashComment(on: Constants.initialStatus)
        makeNetworkAvailable()
    }

    override func tearDown() {
        action = nil
        makeNetworkUnavailable()
        utils.tearDown()
        super.tearDown()
    }

    func testStatusPassedInInitialiserIsPreserved() {
        XCTAssertEqual(action?.on, Constants.initialStatus)
    }

    func testActionTitleIsExpected() {
        XCTAssertEqual(action?.actionTitle, TrashComment.title)
    }

    func testExecuteCallsTrash() {
        action?.on = false

        var executionCompleted = false
        let context = ActionContext(block: utils.mockCommentContent(), content: "content") { (request, success) in
            executionCompleted = true
        }

        action?.execute(context: context)

        XCTAssertTrue(executionCompleted)
    }
}
