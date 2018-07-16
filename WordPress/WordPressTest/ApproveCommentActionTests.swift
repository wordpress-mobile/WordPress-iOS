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
        var unaproveWasCalled: Bool = false
        var aproveWasCalled: Bool = false

        override func unapproveCommentWithBlock(_ block: ActionableObject, completion: ((Bool) -> Void)?) {
            unaproveWasCalled = true
            completion?(true)
        }

        override func approveCommentWithBlock(_ block: ActionableObject, completion: ((Bool) -> Void)?) {
            aproveWasCalled = true
            completion?(true)
        }
    }

    private var action: ApproveComment?

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        action = TestableApproveComment(on: Constants.initialStatus)
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

    func testSettingActionOnSetsExpectedTitle() {
        action?.on = true
        XCTAssertEqual(action?.icon?.titleLabel?.text, ApproveComment.TitleStrings.unapprove)
    }

    func testSettingActionOnSetsExpectedAccessibilityLabel() {
        action?.on = true
        XCTAssertEqual(action?.icon?.accessibilityLabel, ApproveComment.TitleStrings.unapprove)
    }

    func testSettingActionOnSetsExpectedAccessibilityHint() {
        action?.on = true
        XCTAssertEqual(action?.icon?.accessibilityHint, ApproveComment.TitleHints.unapprove)
    }

    func testSettingActionOffSetsExpectedTitle() {
        action?.on = false
        XCTAssertEqual(action?.icon?.titleLabel?.text, ApproveComment.TitleStrings.approve)
    }

    func testSettingActionOffSetsExpectedAccessibilityLabel() {
        action?.on = false
        XCTAssertEqual(action?.icon?.accessibilityLabel, ApproveComment.TitleStrings.approve)
    }

    func testSettingActionOffSetsExpectedAccessibilityHint() {
        action?.on = false
        XCTAssertEqual(action?.icon?.accessibilityHint, ApproveComment.TitleHints.approve)
    }

    func testDefaultTitleIsExpected() {
        XCTAssertEqual(action?.icon?.titleLabel?.text, ApproveComment.TitleStrings.approve)
    }

    func testDefaultAccessibilityLabelIsExpected() {
        XCTAssertEqual(action?.icon?.accessibilityLabel, ApproveComment.TitleStrings.approve)
    }

    func testDefaultAccessibilityHintIsExpected() {
        XCTAssertEqual(action?.icon?.accessibilityHint, ApproveComment.TitleHints.approve)
    }

    func testExecuteCallsUnapproveWhenIconIsOn() {
        action?.on = true

        action?.execute(context: mockActionContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.unaproveWasCalled)
    }

    func testExecuteUpdatesIconTitleWhenIconIsOn() {
        action?.on = true

        action?.execute(context: mockActionContext())

        XCTAssertEqual(action?.icon?.titleLabel?.text, ApproveComment.TitleStrings.approve)
    }

    func testExecuteUpdatesIconAccessibilityLabelWhenIconIsOn() {
        action?.on = true

        action?.execute(context: mockActionContext())

        XCTAssertEqual(action?.icon?.accessibilityLabel, ApproveComment.TitleStrings.approve)
    }

    func testExecuteUpdatesIconAccessibilityHintWhenIconIsOn() {
        action?.on = true

        action?.execute(context: mockActionContext())

        XCTAssertEqual(action?.icon?.accessibilityHint, ApproveComment.TitleHints.approve)
    }

    func testExecuteCallsApproveWhenIconIsOff() {
        action?.on = false

        action?.execute(context: mockActionContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.aproveWasCalled)
    }

    func testExecuteUpdatesIconTitleWhenIconIsOff() {
        action?.on = false

        action?.execute(context: mockActionContext())

        XCTAssertEqual(action?.icon?.titleLabel?.text, ApproveComment.TitleStrings.unapprove)
    }

    func testExecuteUpdatesIconAccessibilityLabelWhenIconIsOff() {
        action?.on = false

        action?.execute(context: mockActionContext())

        XCTAssertEqual(action?.icon?.accessibilityLabel, ApproveComment.TitleStrings.unapprove)
    }

    func testExecuteUpdatesIconAccessibilityHintWhenIconIsOff() {
        action?.on = false

        action?.execute(context: mockActionContext())

        XCTAssertEqual(action?.icon?.accessibilityHint, ApproveComment.TitleHints.unapprove)
    }
}
