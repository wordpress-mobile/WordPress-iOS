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

final class MockActionableObject: ActionableObject {
    var textOverride: String?

    var notificationID: String? {
        return "mockID"
    }

    var metaSiteID: NSNumber? {
        return NSNumber(value: 0)
    }

    var metaCommentID: NSNumber? {
        return NSNumber(value: 0)
    }

    var isCommentApproved: Bool {
        return true
    }

    var text: String? {
        return "Hello"
    }

    func action(id: Identifier) -> FormattableContentAction? {
        return nil
    }
}

final class ApproveCommentActionTests: XCTestCase {
    private var action: ApproveComment?

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        action = TestableApproveComment(on: Constants.initialStatus)
    }

    override func tearDown() {
        action = nil
        super.tearDown()
    }

    func testStatusPassedInInitialiserIsPreserved() {
        XCTAssertEqual(action?.on, Constants.initialStatus)
    }

    func testSettingActionOnSetsExpectedTitle() {
        action?.on = true
        XCTAssertEqual(action?.icon?.titleLabel?.text, ApproveComment.TitleStrings.approve)
    }

    func testSettingActionOnSetsExpectedAccessibilityLabel() {
        action?.on = true
        XCTAssertEqual(action?.icon?.accessibilityLabel, ApproveComment.TitleStrings.approve)
    }

    func testSettingActionOnSetsExpectedAccessibilityHint() {
        action?.on = true
        XCTAssertEqual(action?.icon?.accessibilityHint, ApproveComment.TitleHints.approve)
    }

    func testSettingActionOffSetsExpectedTitle() {
        action?.on = false
        XCTAssertEqual(action?.icon?.titleLabel?.text, ApproveComment.TitleStrings.unapprove)
    }

    func testSettingActionOffSetsExpectedAccessibilityLabel() {
        action?.on = false
        XCTAssertEqual(action?.icon?.accessibilityLabel, ApproveComment.TitleStrings.unapprove)
    }

    func testSettingActionOffSetsExpectedAccessibilityHint() {
        action?.on = false
        XCTAssertEqual(action?.icon?.accessibilityHint, ApproveComment.TitleHints.unapprove)
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

    private func mockContext() -> ActionContext {
        return ActionContext(block: mockActionableObject())
    }

    private func mockActionableObject() -> ActionableObject {
        return MockActionableObject()
    }
}
