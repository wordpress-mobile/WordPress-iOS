import XCTest
@testable import WordPress

fileprivate final class MockNotificationActionsService: NotificationActionsService {
    override func unapproveCommentWithBlock(_ block: ActionableObject, completion: ((Bool) -> Void)?) {
        completion?(true)
    }

    override func approveCommentWithBlock(_ block: ActionableObject, completion: ((Bool) -> Void)?) {
        completion?(true)
    }
}


final class TestableApproveComment: ApproveComment {
    override var actionsService: NotificationActionsService? {
        return MockNotificationActionsService(managedObjectContext: TestContextManager.sharedInstance().mainContext)
    }
}

final class ApproveCommentActionTests: XCTestCase {
    private var action: ApproveComment?

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        action = ApproveComment(on: Constants.initialStatus)
    }

    override func tearDown() {
        action = nil
        super.tearDown()
    }

    func testStatusPassedInInitialiserIsPreserved() {
        XCTAssertEqual(action?.on, Constants.initialStatus)
    }
}
