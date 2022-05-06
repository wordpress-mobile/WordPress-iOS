import XCTest
@testable import WordPress

final class EditCommentActionTests: XCTestCase {
    private class TestableEditComment: EditComment {
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
        var updateWasCalled: Bool = false

        override func updateCommentWithBlock(_ block: FormattableCommentContent, content: String, completion: ((Bool) -> Void)?) {
            updateWasCalled = true
            completion?(true)
        }
    }

    private var action: EditComment?
    private let utility = NotificationUtility()
    private var contextManager: TestContextManager!

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        utility.setUp()
        contextManager = TestContextManager()
        action = TestableEditComment(on: Constants.initialStatus, coreDataStack: contextManager)
    }

    override func tearDown() {
        action = nil
        utility.tearDown()
        ContextManager.overrideSharedInstance(nil)
        super.tearDown()
    }

    func testActionTitleIsExpected() {
        XCTAssertEqual(action?.actionTitle, EditComment.title)
    }

    func testExecuteCallsEdit() throws {
        action?.execute(context: try utility.mockCommentContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.updateWasCalled)
    }
}
