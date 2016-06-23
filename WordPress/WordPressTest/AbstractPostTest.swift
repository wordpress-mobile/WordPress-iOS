import XCTest

@testable import WordPress

class AbstractPostTest: XCTestCase {

    func testTitleForStatus() {
        var status = PostStatusDraft
        var title = AbstractPost.titleForStatus(status)
        XCTAssertTrue(title == "Draft", "Title did not match status")

        status = PostStatusPending
        title = AbstractPost.titleForStatus(status)
        XCTAssertTrue(title == "Pending review", "Title did not match status")

        status = PostStatusPrivate
        title = AbstractPost.titleForStatus(status)
        XCTAssertTrue(title == "Privately published", "Title did not match status")

        status = PostStatusPublish
        title = AbstractPost.titleForStatus(status)
        XCTAssertTrue(title == "Published", "Title did not match status")

        status = PostStatusTrash
        title = AbstractPost.titleForStatus(status)
        XCTAssertTrue(title == "Trashed", "Title did not match status")

        status = PostStatusScheduled
        title = AbstractPost.titleForStatus(status)
        XCTAssertTrue(title == "Scheduled", "Title did not match status")
    }

}
