import XCTest
import WordPressKit
@testable import WordPress

class AbstractPostTest: XCTestCase {

    func testTitleForStatus() {
        var status = PostStatusDraft
        var title = AbstractPost.title(forStatus: status)
        XCTAssertTrue(title == NSLocalizedString("Draft", comment: "Name for the status of a draft post."), "Title did not match status")

        status = PostStatusPending
        title = AbstractPost.title(forStatus: status)
        XCTAssertTrue(title == NSLocalizedString("Pending review", comment: "Pending review"), "Title did not match status")

        status = PostStatusPrivate
        title = AbstractPost.title(forStatus: status)
         XCTAssertTrue(title == NSLocalizedString("Private", comment: "Name for the status of a post that is marked private."), "Title did not match status")

        status = PostStatusPublish
        title = AbstractPost.title(forStatus: status)
        XCTAssertTrue(title == NSLocalizedString("Published", comment: "Published"), "Title did not match status")

        status = PostStatusTrash
        title = AbstractPost.title(forStatus: status)
        XCTAssertTrue(title == NSLocalizedString("Trashed", comment: "Trashed"), "Title did not match status")

        status = PostStatusScheduled
        title = AbstractPost.title(forStatus: status)
        XCTAssertTrue(title == NSLocalizedString("Scheduled", comment: "Scheduled"), "Title did not match status")
    }

    func testFeaturedImageURLForDisplay() {
        let post = PostBuilder().with(pathForDisplayImage: "https://wp.me/awesome.png").build()

        XCTAssertEqual(post.featuredImageURLForDisplay()?.absoluteString, "https://wp.me/awesome.png")
    }

}
