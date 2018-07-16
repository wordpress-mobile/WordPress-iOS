import XCTest
@testable import WordPress

final class MarkAsSpamActionTests: XCTestCase {
    private class TestableMarkAsSpam: MarkAsSpam {
        let service = MockNotificationActionsService(managedObjectContext: TestContextManager.sharedInstance().mainContext)
        override var actionsService: NotificationActionsService? {
            return service
        }
    }

    private class MockNotificationActionsService: NotificationActionsService {
        override func spamCommentWithBlock(_ block: ActionableObject, completion: ((Bool) -> Void)?) {
            completion?(true)
        }
    }

    private var action: MarkAsSpam?

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        action = TestableMarkAsSpam(on: Constants.initialStatus)
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
        XCTAssertEqual(action?.icon?.titleLabel?.text, MarkAsSpam.title)
    }

    func testDefaultAccessibilityLabelIsExpected() {
        XCTAssertEqual(action?.icon?.accessibilityLabel, MarkAsSpam.title)
    }

    func testDefaultAccessibilityHintIsExpected() {
        XCTAssertEqual(action?.icon?.accessibilityHint, MarkAsSpam.hint)
    }

    func testExecuteCallsSpam() {
        action?.on = false

        var executionCompleted = false

        let context = ActionContext(block: MockActionableObject(), content: "content") { (request, success) in
            executionCompleted = true
        }

        action?.execute(context: context)

        XCTAssertTrue(executionCompleted)
    }
}
