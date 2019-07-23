import XCTest
@testable import WordPress

final class ApproveCommentActionTests: XCTestCase {
    private class TestableApproveComment: ApproveComment {
        let service = MockNotificationActionsService(managedObjectContext: TestContextManager.sharedInstance().mainContext)
        override var actionsService: NotificationActionsService? {
            return service
        }
    }

    private class MockNotificationActionsService: NotificationActionsService {
        var unapproveWasCalled: Bool = false
        var approveWasCalled: Bool = false

        override func unapproveCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)?) {
            unapproveWasCalled = true
            completion?(true)
        }

        override func approveCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)?) {
            approveWasCalled = true
            completion?(true)
        }
    }

    private var action: ApproveComment?

    private var mockHandler: UIContextualAction.Handler = { (_, _, _) in }

    private let utility = NotificationUtility()

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        utility.setUp()
        action = TestableApproveComment(on: Constants.initialStatus)
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
        XCTAssertEqual(contextualAction?.title, ApproveComment.TitleStrings.approve)
    }

    func testSettingActionOnSetsExpectedTitle() {
        action?.on = true

        let contextualAction = action?.action(handler: mockHandler)
        XCTAssertEqual(contextualAction?.title, ApproveComment.TitleStrings.unapprove)
    }

    func testSettingActionOffSetsExpectedTitle() {
        action?.on = false

        let contextualAction = action?.action(handler: mockHandler)
        XCTAssertEqual(contextualAction?.title, ApproveComment.TitleStrings.approve)
    }

    func testExecuteCallsUnapproveWhenActionIsOn() {
        action?.on = true

        action?.execute(context: utility.mockCommentContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.unapproveWasCalled)
    }

    func testExecuteUpdatesContextualActionTitleWhenActionIsOn() {
        action?.on = true

        action?.execute(context: utility.mockCommentContext())

        let contextualAction = action?.action(handler: mockHandler)
        XCTAssertEqual(contextualAction?.title, ApproveComment.TitleStrings.approve)
    }

    func testExecuteCallsApproveWhenActionIsOff() {
        action?.on = false

        action?.execute(context: utility.mockCommentContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.approveWasCalled)
    }

    func testExecuteUpdatesContextualActionTitleWhenActionIsOff() {
        action?.on = false

        action?.execute(context: utility.mockCommentContext())

        let contextualAction = action?.action(handler: mockHandler)
        XCTAssertEqual(contextualAction?.title, ApproveComment.TitleStrings.unapprove)
    }
}
