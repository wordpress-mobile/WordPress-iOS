import XCTest
@testable import WordPress

final class LikeCommentActionTests: XCTestCase {
    private class TestableLikeComment: LikeComment {
        let service = MockNotificationActionsService(managedObjectContext: TestContextManager.sharedInstance().mainContext)
        override var actionsService: NotificationActionsService? {
            return service
        }
    }

    private class MockNotificationActionsService: NotificationActionsService {
        var likeWasCalled: Bool = false
        var unlikeWasCalled: Bool = false

        override func likeCommentWithBlock(_ block: ActionableObject, completion: ((Bool) -> Void)?) {
            likeWasCalled = true
            completion?(true)
        }

        override func unlikeCommentWithBlock(_ block: ActionableObject, completion: ((Bool) -> Void)?) {
            unlikeWasCalled = true
            completion?(true)
        }
    }

    private var action: LikeComment?

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        action = TestableLikeComment(on: Constants.initialStatus)
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
        XCTAssertEqual(action?.icon?.titleLabel?.text, LikeComment.TitleStrings.like)
    }

    func testSettingActionOnSetsExpectedAccessibilityLabel() {
        action?.on = true
        XCTAssertEqual(action?.icon?.accessibilityLabel, LikeComment.TitleStrings.like)
    }

    func testSettingActionOnSetsExpectedAccessibilityHint() {
        action?.on = true
        XCTAssertEqual(action?.icon?.accessibilityHint, LikeComment.TitleHints.like)
    }

    func testSettingActionOffSetsExpectedTitle() {
        action?.on = false
        XCTAssertEqual(action?.icon?.titleLabel?.text, LikeComment.TitleStrings.unlike)
    }

    func testSettingActionOffSetsExpectedAccessibilityLabel() {
        action?.on = false
        XCTAssertEqual(action?.icon?.accessibilityLabel, LikeComment.TitleStrings.unlike)
    }

    func testSettingActionOffSetsExpectedAccessibilityHint() {
        action?.on = false
        XCTAssertEqual(action?.icon?.accessibilityHint, LikeComment.TitleHints.unlike)
    }

    func testDefaultTitleIsExpected() {
        XCTAssertEqual(action?.icon?.titleLabel?.text, LikeComment.TitleStrings.like)
    }

    func testDefaultAccessibilityLabelIsExpected() {
        XCTAssertEqual(action?.icon?.accessibilityLabel, LikeComment.TitleStrings.like)
    }

    func testDefaultAccessibilityHintIsExpected() {
        XCTAssertEqual(action?.icon?.accessibilityHint, LikeComment.TitleHints.like)
    }

    func testExecuteCallsUnlikeWhenIconIsOn() {
        action?.on = true

        action?.execute(context: mockActionContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.unlikeWasCalled)
    }

    func testExecuteUpdatesIconTitleWhenIconIsOn() {
        action?.on = true

        action?.execute(context: mockActionContext())

        XCTAssertEqual(action?.icon?.titleLabel?.text, LikeComment.TitleStrings.like)
    }

    func testExecuteUpdatesIconAccessibilityLabelWhenIconIsOn() {
        action?.on = true

        action?.execute(context: mockActionContext())

        XCTAssertEqual(action?.icon?.accessibilityLabel, LikeComment.TitleStrings.like)
    }

    func testExecuteUpdatesIconAccessibilityHintWhenIconIsOn() {
        action?.on = true

        action?.execute(context: mockActionContext())

        XCTAssertEqual(action?.icon?.accessibilityHint, LikeComment.TitleHints.like)
    }

    func testExecuteCallsApproveWhenIconIsOff() {
        action?.on = false

        action?.execute(context: mockActionContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.likeWasCalled)
    }

    func testExecuteUpdatesIconTitleWhenIconIsOff() {
        action?.on = false

        action?.execute(context: mockActionContext())

        XCTAssertEqual(action?.icon?.titleLabel?.text, LikeComment.TitleStrings.unlike)
    }

    func testExecuteUpdatesIconAccessibilityLabelWhenIconIsOff() {
        action?.on = false

        action?.execute(context: mockActionContext())

        XCTAssertEqual(action?.icon?.accessibilityLabel, LikeComment.TitleStrings.unlike)
    }

    func testExecuteUpdatesIconAccessibilityHintWhenIconIsOff() {
        action?.on = false

        action?.execute(context: mockActionContext())

        XCTAssertEqual(action?.icon?.accessibilityHint, LikeComment.TitleHints.unlike)
    }
}
