import XCTest
@testable import WordPress

final class ReplyToCommentActionTests: XCTestCase {
    private class TestableReplyToComment: ReplyToComment {
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
        var replyWasCalled: Bool = false
        override func replyCommentWithBlock(_ block: FormattableCommentContent, content: String, completion: ((Bool) -> Void)?) {
            replyWasCalled = true
            completion?(true)
        }
    }

    private var action: ReplyToComment?
    let utility = NotificationUtility()
    private var testContextManager: TestContextManager!

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        utility.setUp()
        testContextManager = TestContextManager()
        action = TestableReplyToComment(on: Constants.initialStatus, coreDataStack: testContextManager)
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

    func testActionTitleIsExpected() {
        XCTAssertEqual(action?.actionTitle, ReplyToComment.title)
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
