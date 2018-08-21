@testable import WordPress
import XCTest

class MockContentProvider: NSObject, ReaderPostContentProvider {
    func titleForDisplay() -> String! {
        return "A title"
    }

    func authorForDisplay() -> String! {
        return "An author"
    }

    func blogNameForDisplay() -> String! {
        return "A blog name"
    }

    func statusForDisplay() -> String! {
        return "A status"
    }

    func contentForDisplay() -> String! {
        return "The post content"
    }

    func contentPreviewForDisplay() -> String! {
        return "The preview content"
    }

    func avatarURLForDisplay() -> URL! {
        return URL(string: "http://automattic.com")!
    }

    func gravatarEmailForDisplay() -> String! {
        return "auto@automattic.com"
    }

    func dateForDisplay() -> Date! {
        return Date(timeIntervalSince1970: 0)
    }

    func siteIconForDisplay(ofSize size: Int) -> URL! {
        return avatarURLForDisplay()
    }

    func sourceAttributionStyle() -> SourceAttributionStyle {
        return .post
    }

    func sourceAuthorNameForDisplay() -> String! {
        return "An author name"
    }

    func sourceAuthorURLForDisplay() -> URL! {
        return URL(string: "http://automattic.com")
    }

    func sourceAvatarURLForDisplay() -> URL! {
        return sourceAuthorURLForDisplay()
    }

    func sourceBlogNameForDisplay() -> String! {
        return blogNameForDisplay()
    }

    func sourceBlogURLForDisplay() -> URL! {
        return avatarURLForDisplay()
    }

    func likeCountForDisplay() -> String! {
        return "2"
    }

    func commentCount() -> NSNumber! {
        return 2
    }

    func likeCount() -> NSNumber! {
        return 1
    }

    func commentsOpen() -> Bool {
        return true
    }

    func isFollowing() -> Bool {
        return true
    }

    func isLikesEnabled() -> Bool {
        return true
    }

    func isPrivate() -> Bool {
        return false
    }

    func isLiked() -> Bool {
        return true
    }

    func isExternal() -> Bool {
        return false
    }

    func isJetpack() -> Bool {
        return true
    }

    func isWPCom() -> Bool {
        return false
    }

    func primaryTag() -> String! {
        return "Primary tag"
    }

    func readingTime() -> NSNumber! {
        return 0
    }

    func wordCount() -> NSNumber! {
        return 10
    }

    func siteURLForDisplay() -> String! {
        return "http://automattic.com"
    }

    func crossPostOriginSiteURLForDisplay() -> String! {
        return ""
    }

    func isCommentCrossPost() -> Bool {
        return false
    }

    func isSavedForLater() -> Bool {
        return false
    }
}

final class ReaderPostCardCellTests: XCTestCase {

    private var cell: ReaderPostCardCell?
    private var mock: ReaderPostContentProvider?

    private struct TestConstants {
        static let headerLabel = "Post by An author, from A blog name, "
        static let saveLabel = "Save post"
        static let shareLabel = "Share"
        static let moreLabel = "More"
        static let commentLabel = "2 comments"
        static let visitLabel = "Visit"
    }

    override func setUp() {
        super.setUp()
        mock = MockContentProvider()
        cell = Bundle.loadRootViewFromNib(type: ReaderPostCardCell.self)
        cell?.configureCell(mock!)
    }

    override func tearDown() {
        cell = nil
        mock = nil
        super.tearDown()
    }

    func testHeaderLabelMatchesExpectation() {
        let expectedHeaderLabel = TestConstants.headerLabel + mock!.dateForDisplay().mediumString()
        XCTAssertEqual(cell?.getHeaderButtonForTesting().accessibilityLabel, expectedHeaderLabel, "Incorrect accessibility label: Header Button ")
    }

    func testSaveForLaterButtonLabelMatchesExpectation() {
        let validLabelText = TestConstants.saveLabel
        XCTAssertEqual(cell?.getSaveForLaterButtonForTesting().accessibilityLabel, validLabelText, "Incorrect accessibility label: Save for Later button")
    }

    func testCommentsButtonLabelMatchesExpectation() {
        XCTAssertEqual(cell?.getCommentsButtonForTesting().accessibilityLabel, TestConstants.commentLabel, "Incorrect accessibility label: Comments button")
    }

    func testMenuButtonLabelMatchesExpectation() {
        XCTAssertEqual(cell?.getMenuButtonForTesting().accessibilityLabel, TestConstants.moreLabel, "Incorrect accessibility label: Menu button")
    }

    func testVisitButtonLabelMatchesExpectation() {
        XCTAssertEqual(cell?.getVisitButtonForTesting().accessibilityLabel, TestConstants.visitLabel, "Incorrect accessibility label: Visit button"
    )
    }
}
