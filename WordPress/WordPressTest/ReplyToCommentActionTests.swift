import XCTest
@testable import WordPress

final class ReplyToCommentActionTests: CoreDataTestCase {
    private class TestableReplyToComment: ReplyToComment {
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
        var replyWasCalled: Bool = false
        override func replyCommentWithBlock(_ block: FormattableCommentContent, content: String, completion: ((Bool) -> Void)?) {
            replyWasCalled = true
            completion?(true)
        }
    }

    private var action: ReplyToComment?
    private var utility: NotificationUtility!

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        utility = NotificationUtility(coreDataStack: contextManager)
        action = TestableReplyToComment(on: Constants.initialStatus, coreDataStack: contextManager)
        makeNetworkAvailable()
    }

    override func tearDown() {
        action = nil
        makeNetworkUnavailable()
        utility = nil
    }

    func testStatusPassedInInitialiserIsPreserved() {
        XCTAssertEqual(action?.on, Constants.initialStatus)
    }

    func testActionTitleIsExpected() {
        XCTAssertEqual(action?.actionTitle, ReplyToComment.title)
    }

    func testExecuteCallsReply() throws {
        action?.execute(context: try utility.mockCommentContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.replyWasCalled)
    }

}
