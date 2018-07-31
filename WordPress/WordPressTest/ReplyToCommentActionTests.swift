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
        override func replyCommentWithBlock(_ block: ActionableObject, content: String, completion: ((Bool) -> Void)?) {
            replyWasCalled = true
            completion?(true)
        }
    }

    private var action: ReplyToComment?

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        action = TestableReplyToComment(on: Constants.initialStatus)
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
        XCTAssertEqual(action?.icon?.titleLabel?.text, ReplyToComment.title)
    }

    func testDefaultAccessibilityLabelIsExpected() {
        XCTAssertEqual(action?.icon?.accessibilityLabel, ReplyToComment.title)
    }

    func testDefaultAccessibilityHintIsExpected() {
        XCTAssertEqual(action?.icon?.accessibilityHint, ReplyToComment.hint)
    }

    func testExecuteCallsReply() {
        action?.execute(context: mockActionContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.replyWasCalled)
    }

}
