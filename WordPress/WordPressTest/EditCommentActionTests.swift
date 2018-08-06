import XCTest
@testable import WordPress

final class EditCommentActionTests: XCTestCase {
    private class TestableEditComment: EditComment {
        let service = MockNotificationActionsService(managedObjectContext: TestContextManager.sharedInstance().mainContext)
        override var actionsService: NotificationActionsService? {
            return service
        }
    }

    private class MockNotificationActionsService: NotificationActionsService {
        var updateWasCalled: Bool = false

        override func updateCommentWithBlock(_ block: ActionableObject, content: String, completion: ((Bool) -> Void)?) {
            updateWasCalled = true
            completion?(true)
        }
    }

    private var action: EditComment?

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        action = TestableEditComment(on: Constants.initialStatus)
    }

    override func tearDown() {
        action = nil
        super.tearDown()
    }

    func testDefaultTitleIsExpected() {
        XCTAssertEqual(action?.icon?.titleLabel?.text, EditComment.title)
    }

    func testDefaultAccessibilityLabelIsExpected() {
        XCTAssertEqual(action?.icon?.accessibilityLabel, EditComment.title)
    }

    func testDefaultAccessibilityHintIsExpected() {
        XCTAssertEqual(action?.icon?.accessibilityHint, EditComment.hint)
    }

    func testExecuteCallsEdit() {
        action?.execute(context: mockActionContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.updateWasCalled)
    }
}
