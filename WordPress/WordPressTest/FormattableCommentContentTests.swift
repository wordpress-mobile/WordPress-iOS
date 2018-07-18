import XCTest
@testable import WordPress

final class FormattableCommentContentTests: XCTestCase {
    private let contextManager = TestContextManager()
    private let entityName = Notification.classNameWithoutNamespaces()

    private var subject: FormattableCommentContent?

    private struct Expectations {
        static let text = "This is an unapproved comment"
        static let approveAction = ApproveCommentAction(on: true, command: ApproveComment(on: true))
        static let trashAction = TrashCommentAction(on: true, command: TrashComment(on: true))
        static let commentID = NSNumber(integerLiteral: 7)
    }

    override func setUp() {
        super.setUp()
        subject = FormattableCommentContent(dictionary: mockDictionary(), actions: mockedActions(), ranges: [], parent: loadLikeNotification())
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testKindReturnsExpectation() {
        let notificationKind = subject?.kind

        XCTAssertEqual(notificationKind, .comment)
    }

    func testStringReturnsExpectation() {
        let value = subject?.text

        XCTAssertEqual(value, Expectations.text)
    }

    func testRangesAreEmpty() {
        let value = subject?.ranges

        XCTAssertEqual(value?.count, 0)
    }

    func testActionsReturnMockedActions() {
        let value = subject?.actions
        let mockActionsCount = mockedActions().count

        XCTAssertEqual(value?.count, mockActionsCount)
    }

    func testMetaReturnsExpectation() {
        let value = subject!.meta!
        let ids = value["ids"] as? [String: AnyObject]
        let commentId = ids?["comment"] as? String
        let postId = ids?["post"] as? String

        let mockMeta = loadMeta()
        let mockIds = mockMeta["ids"] as? [String: AnyObject]
        let mockMetaCommentId = mockIds?["comment"] as? String
        let mockMetaPostId = mockIds?["post"] as? String

        XCTAssertEqual(commentId, mockMetaCommentId)
        XCTAssertEqual(postId, mockMetaPostId)
    }

    func testParentReturnsValuePassedAsParameter() {
        let injectedParent = loadLikeNotification()

        let parent = subject?.parent

        XCTAssertEqual(parent?.uniqueID, injectedParent.uniqueID)
    }

    func testApproveCommentActionIsOn() {
        let approveCommentIdentifier = ApproveCommentAction.actionIdentifier()
        let on = subject?.isActionOn(id: approveCommentIdentifier)
        XCTAssertTrue(on!)
    }

    func testApproveCommentActionIsEnabled() {
        let approveCommentIdentifier = ApproveCommentAction.actionIdentifier()
        let on = subject?.isActionEnabled(id: approveCommentIdentifier)
        XCTAssertTrue(on!)
    }

    func testActionWithIdentifierReturnsExpectedAction() {
        let approveCommentIdentifier = ApproveCommentAction.actionIdentifier()
        let action = subject?.action(id: approveCommentIdentifier)
        XCTAssertEqual(action?.identifier, approveCommentIdentifier)
    }

    func testMetaCommentIdReturnsExpectation() {
        let id = subject?.metaCommentID

        XCTAssertEqual(id, Expectations.commentID)
    }

    func testIsCommentApprovedReturnsExpectation() {
        XCTAssertTrue(subject!.isCommentApproved)
    }

    private func mockDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "notifications-comment-content.json")
    }

    private func getDictionaryFromFile(named fileName: String) -> [String: AnyObject] {
        return contextManager.object(withContentOfFile: fileName) as! [String: AnyObject]
    }

    private func loadLikeNotification() -> WordPress.Notification {
        return contextManager.loadEntityNamed(entityName, withContentsOfFile: "notifications-like.json") as! WordPress.Notification
    }

    private func loadMeta() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "notifications-comment-meta.json")
    }

    private func mockedActions() -> [FormattableContentAction] {
        return [Expectations.approveAction,
                Expectations.trashAction]
    }
}
