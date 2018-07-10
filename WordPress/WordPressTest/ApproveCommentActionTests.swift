import XCTest
@testable import WordPress

final class TestableApproveComment: ApproveComment {
    override var actionsService: NotificationActionsService? {
        return NotificationActionsService(managedObjectContext: TestContextManager.sharedInstance().mainContext)
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
