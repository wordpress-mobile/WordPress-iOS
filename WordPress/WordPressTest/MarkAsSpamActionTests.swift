import XCTest
@testable import WordPress

final class MarkAsSpamActionTests: XCTestCase {
    private class TestableMarkAsSpam: MarkAsSpam {
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
        override func spamCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)?) {
            completion?(true)
        }
    }

    private var action: MarkAsSpam?
    let utility = NotificationUtility()
    private var testContextManager: TestContextManager!

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        utility.setUp()
        testContextManager = TestContextManager()
        action = TestableMarkAsSpam(on: Constants.initialStatus, coreDataStack: testContextManager)
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
        XCTAssertEqual(action?.actionTitle, MarkAsSpam.title)
    }

    func testExecuteCallsSpam() throws {
        action?.on = false

        var executionCompleted = false

        let context = ActionContext(block: try utility.mockCommentContent(), content: "content") { (request, success) in
            executionCompleted = true
        }

        action?.execute(context: context)

        XCTAssertTrue(executionCompleted)
    }
}
