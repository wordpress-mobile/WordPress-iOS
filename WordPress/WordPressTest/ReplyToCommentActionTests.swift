import XCTest
@testable import WordPress

final class ReplyToCommentActionTests: XCTestCase {
    private class TestableReplyToComment: ReplyToComment {
        let service = MockNotificationActionsService(managedObjectContext: TestContextManager.sharedInstance().mainContext)
        override var actionsService: NotificationActionsService? {
            return service
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

    private var mockHandler: UIContextualAction.Handler = { (_, _, _) in }

    let utility = NotificationUtility()

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        utility.setUp()
        action = TestableReplyToComment(on: Constants.initialStatus)
        makeNetworkAvailable()
    }

    override func tearDown() {
        action = nil
        makeNetworkUnavailable()
        utility.tearDown()
        super.tearDown()
    }

    func testStatusPassedInInitialiserIsPreserved() {
        XCTAssertEqual(action?.on, Constants.initialStatus)
    }

    func testContextualActionTitleIsExpected() {
        let contextualAction = action?.action(handler: mockHandler)
        XCTAssertEqual(contextualAction?.title, ReplyToComment.title)
    }

    func testExecuteCallsReply() {
        action?.execute(context: utility.mockCommentContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.replyWasCalled)
    }

}
