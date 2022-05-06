import XCTest
@testable import WordPress

final class TrashCommentActionTests: XCTestCase {
    private class TestableTrashComment: TrashComment {
        let service: MockNotificationActionsService
        override var actionsService: NotificationActionsService? {
            return service
        }

        init(on: Bool, coreDataStack: CoreDataStack) {
            service = MockNotificationActionsService(managedObjectContext: coreDataStack.mainContext)
            super.init(on: on)
        }
    }

    private class MockNotificationActionsService: NotificationActionsService {
        override func deleteCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)?) {
            completion?(true)
        }
    }

    private var action: TrashComment?
    let utils = NotificationUtility()
    private var testContextManager: TestContextManager!

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        utils.setUp()
        testContextManager = TestContextManager()
        action = TestableTrashComment(on: Constants.initialStatus, coreDataStack: testContextManager)
        makeNetworkAvailable()
    }

    override func tearDown() {
        action = nil
        makeNetworkUnavailable()
        utils.tearDown()
        testContextManager.tearDown()
        super.tearDown()
    }

    func testStatusPassedInInitialiserIsPreserved() {
        XCTAssertEqual(action?.on, Constants.initialStatus)
    }

    func testActionTitleIsExpected() {
        XCTAssertEqual(action?.actionTitle, TrashComment.title)
    }

    func testExecuteCallsTrash() throws {
        action?.on = false

        var executionCompleted = false
        let context = ActionContext(block: try utils.mockCommentContent(), content: "content") { (request, success) in
            executionCompleted = true
        }

        action?.execute(context: context)

        XCTAssertTrue(executionCompleted)
    }
}
