import XCTest
@testable import WordPress

final class EditCommentActionTests: CoreDataTestCase {
    private class TestableEditComment: EditComment {
        let service: MockNotificationActionsService

        override var actionsService: NotificationActionsService? {
            return service
        }

        init(on: Bool, coreDataStack: CoreDataStack) {
            service = MockNotificationActionsService(coreDataStack: coreDataStack)
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
    private var utility: NotificationUtility!

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        utility = NotificationUtility(coreDataStack: contextManager)
        action = TestableEditComment(on: Constants.initialStatus, coreDataStack: contextManager)
    }

    override func tearDown() {
        action = nil
        utility = nil
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
