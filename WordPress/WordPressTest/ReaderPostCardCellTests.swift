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


}

final class ReaderPostCardCellTests: XCTestCase {


    private var cell: ReaderPostCardCell?


    override func setUp() {
        super.setUp()
//        let nib = Bundle.main.loadNibNamed("ReaderPostCardCell", owner: self, options: nil)
//        cell = nib?.first as? ReaderPostCardCell
        cell = Bundle.loadRootViewFromNib(type: ReaderPostCardCell.self)
        cell?.configureCell(MockContentProvider())
    }
    
    override func tearDown() {
        cell = nil
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
