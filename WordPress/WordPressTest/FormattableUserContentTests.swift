import XCTest
@testable import WordPress

final class FormattableUserContentTests: XCTestCase {
    private let contextManager = TestContextManager()
    private let entityName = Notification.classNameWithoutNamespaces()

    private var subject: FormattableUserContent?

    private struct Expectations {
        static let text = "someonesomeone"
        static let approveAction = ApproveCommentAction(on: true, command: ApproveComment(on: true))
        static let trashAction = TrashCommentAction(on: true, command: TrashComment(on: true))
        static let metaTitlesHome = "a title"
        static let metaTitlesHomeURL = URL(string: "http://someone.wordpress.com")
        static let notificationId = "11111"
        static let metaSiteId = NSNumber(integerLiteral: 136505344)
    }

    override func setUp() {
        super.setUp()
        subject = FormattableUserContent(dictionary: mockDictionary(), actions: mockedActions(), ranges: [], parent: loadLikeNotification())
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testKindReturnsExpectation() {
        let notificationKind = subject?.kind

        XCTAssertEqual(notificationKind, .user)
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
        let userId = ids?["user"] as? String
        let siteId = ids?["site"] as? String

        let mockMeta = loadMeta()
        let mockIds = mockMeta["ids"] as? [String: AnyObject]
        let mockMetaUserId = mockIds?["user"] as? String
        let mockMetaSiteId = mockIds?["site"] as? String

        XCTAssertEqual(userId, mockMetaUserId)
        XCTAssertEqual(siteId, mockMetaSiteId)
    }

    func testParentReturnsValuePassedAsParameter() {
        let injectedParent = loadLikeNotification()

        let parent = subject?.parent

        XCTAssertEqual(parent?.notificationId, injectedParent.notificationId)
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

    func testMetaTitlesHomeAsStringReturnsExpectation() {
        let home: String? = subject?.metaTitlesHome
        XCTAssertEqual(home, Expectations.metaTitlesHome)
    }

    func testMetaTitlesHomeAsURLReturnsExpectation() {
        let home: URL? = subject?.metaLinksHome
        XCTAssertEqual(home, Expectations.metaTitlesHomeURL)
    }

    func testNotificationIdReturnsExpectation() {
        let id = subject?.notificationID
        XCTAssertEqual(id, Expectations.notificationId)
    }

    func testMetaSiteIdReturnsExpectation() {
        let id = subject?.metaSiteID
        XCTAssertEqual(id, Expectations.metaSiteId)
    }

    func testMetaCommentIdReturnsExpectation() {
        let id = subject?.metaCommentID
        XCTAssertNil(id)
    }

    func testIsCommentApprovedReturnsExpectation() {
        let value = subject?.isCommentApproved
        XCTAssertFalse(value!)
    }

    private func mockDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "notifications-user-content.json")
    }

    private func getDictionaryFromFile(named fileName: String) -> [String: AnyObject] {
        return contextManager.object(withContentOfFile: fileName) as! [String: AnyObject]
    }

    private func loadLikeNotification() -> WordPress.Notification {
        return contextManager.loadEntityNamed(entityName, withContentsOfFile: "notifications-like.json") as! WordPress.Notification
    }

    private func loadMeta() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "notifications-user-content-meta.json")
    }

    private func mockedActions() -> [FormattableContentAction] {
        return [Expectations.approveAction,
                Expectations.trashAction]
    }
}
