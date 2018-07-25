import XCTest
@testable import WordPress

final class NotificationBlockTests: XCTestCase {
    private let contextManager = TestContextManager()
    private let entityName = Notification.classNameWithoutNamespaces()

    private var subject: NotificationBlock?

    private struct Expectations {
        static let approveAction = ApproveCommentAction(on: true, command: ApproveComment(on: true))
        static let trashAction = TrashCommentAction(on: true, command: TrashComment(on: true))
        static let mediaCount = 0
        static let rangesCount = 2
        static let text = "Jennifer Parks and 658 others liked your post Bookmark Posts with Save For Later"
        static let kind = NotificationBlock.Kind.text
        static let notificationID = "11111"
    }

    override func setUp() {
        super.setUp()
        subject = NotificationBlock(dictionary: mockDictionary(), parent: loadLikeNotification())
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testMediaContainsExpectedItems() {
        let media = subject?.media

        XCTAssertEqual(media?.count, Expectations.mediaCount)
    }

    func testRangesContainsExpectedItems() {
        let ranges = subject?.ranges

        XCTAssertEqual(ranges?.count, Expectations.rangesCount)
    }

    func testTextContainsExpectedText() {
        let text = subject?.text

        XCTAssertEqual(text, Expectations.text)
    }

    func testTextOverrideDefaultsToNil() {
        let textOverride = subject?.textOverride

        XCTAssertNil(textOverride)
    }

    func testKindReturnsExpectedKind() {
        let kind = subject?.kind

        XCTAssertEqual(kind, Expectations.kind)
    }

    func testImageURLsReturnsEmpty() {
        let imageURLs = subject!.imageUrls

        XCTAssertTrue(imageURLs.count == 0)
    }

    func testIsCommentApprovedReturnsApproveActionStatus() {
        let isCommentApproved = subject!.isCommentApproved

        XCTAssertTrue(isCommentApproved)
    }

    func testMetaCommentIdIsExpected() {
        let metaCommentId = subject!.metaCommentID

        XCTAssertNil(metaCommentId)
    }

    func testMetaLinksHomeIsExpected() {
        let metaLinksHome = subject!.metaLinksHome

        XCTAssertNil(metaLinksHome)
    }

    func testMetaSiteIdIsExpected() {
        let metaSiteID = subject!.metaSiteID

        XCTAssertNil(metaSiteID)
    }

    func testMetaTitlesHomeIsExpected() {
        let metaTitlesHome = subject!.metaTitlesHome

        XCTAssertNil(metaTitlesHome)
    }

    func testNotificationIdIsExpected() {
        let notificationID = subject!.notificationID

        XCTAssertEqual(notificationID, Expectations.notificationID)
    }

    private func mockDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "notifications-text-content.json")
    }

    private func getDictionaryFromFile(named fileName: String) -> [String: AnyObject] {
        return contextManager.object(withContentOfFile: fileName) as! [String: AnyObject]
    }

    private func mockActions() -> [FormattableContentAction] {
        return [Expectations.approveAction,
                Expectations.trashAction]
    }

    private func loadLikeNotification() -> WordPress.Notification {
        return contextManager.loadEntityNamed(entityName, withContentsOfFile: "notifications-like.json") as! WordPress.Notification
    }
}
