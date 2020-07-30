@testable import WordPress
import XCTest

class MockContentProvider: NSObject, ReaderPostContentProvider {
    func siteID() -> NSNumber {
        return NSNumber(value: 15546)
    }

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
        // will make all buttons visible
        return .none
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

    func isAtomic() -> Bool {
        return false
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

    func siteHostNameForDisplay() -> String! {
        return "automattic.com"
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
        static let headerLabel = NSLocalizedString("Post by %@, from %@", comment: "")
        static let saveLabel = NSLocalizedString("Save post", comment: "Save post")
        static let moreLabel = NSLocalizedString("More", comment: "More")
        static let commentsLabelformat = NSLocalizedString("%@ comments", comment: "Number of Comments")
        static let reblogLabel = NSLocalizedString("Reblog post", comment: "Accessibility label for the reblog button.")
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
        XCTAssertEqual(cell?.getHeaderButtonForTesting().accessibilityLabel, String(format: TestConstants.headerLabel, "An author", "A blog name" + ", " + mock!.dateForDisplay().mediumString()), "Incorrect accessibility label: Header Button ")
    }

    func testSaveForLaterButtonLabelMatchesExpectation() {
        XCTAssertEqual(cell?.getSaveForLaterButtonForTesting().accessibilityLabel, String(format: "%@", TestConstants.saveLabel), "Incorrect accessibility label: Save for Later button")
    }

    func testCommentsButtonLabelMatchesExpectation() {
        XCTAssertEqual(cell?.getCommentsButtonForTesting().accessibilityLabel, String(format: TestConstants.commentsLabelformat, "\(2)"), "Incorrect accessibility label: Comments button")
    }

    func testMenuButtonLabelMatchesExpectation() {
        XCTAssertEqual(cell?.getMenuButtonForTesting().accessibilityLabel, String(format: "%@", TestConstants.moreLabel), "Incorrect accessibility label: Menu button")
    }

    func testReblogActionButtonMatchesExpectation() {
        XCTAssertEqual(cell?.getReblogButtonForTesting().accessibilityLabel, TestConstants.reblogLabel, "Incorrect accessibility label: Reblog button")
    }

    func testReblogButtonIsVisible() {
        guard let button = cell?.getReblogButtonForTesting() else {
            XCTFail("Reblog button not found.")
            return
        }
        XCTAssertFalse(button.isHidden, "Reblog button should be visible.")
    }

    func testReblogButtonVisibleWithNoLoggedInUser() {
        cell?.loggedInActionVisibility = .visible(enabled: false)
        cell?.configureCell(mock!)

        guard let button = cell?.getReblogButtonForTesting() else {
            XCTFail("Reblog button not found.")
            return
        }
        XCTAssertFalse(button.isEnabled, "Reblog button should be disabled.")
    }
}
