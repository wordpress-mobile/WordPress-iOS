import XCTest
import WordPressKit
@testable import WordPress

class AbstractPostTest: CoreDataTestCase {

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
        let post = PostBuilder(mainContext).with(pathForDisplayImage: "https://wp.me/awesome.png").build()

        XCTAssertEqual(post.featuredImageURLForDisplay()?.absoluteString, "https://wp.me/awesome.png")
    }

    func testGetLatestRevisionNeedingSync() {
        // GIVEN a post with no revisions
        let post = PostBuilder(mainContext).build()

        // THEN
        XCTAssertNil(post.getLatestRevisionNeedingSync())

        // GIVEN a post with a revision that doesn't need sync
        let revision1 = post.createRevision()

        // THEN
        XCTAssertNil(post.getLatestRevisionNeedingSync())

        // GIVEN a post with a revision that needs sync
        let revision2 = revision1.createRevision()
        revision2.remoteStatus = .syncNeeded

        // THEN
        XCTAssertEqual(post.getLatestRevisionNeedingSync(), revision2)
    }

    func testDeleteSyncedRevisions() {
        // GIVEN a post with three revisions
        let post = PostBuilder(mainContext).build()
        let revision1 = post.createRevision()
        let revision2 = revision1.createRevision()
        let revision3 = revision2.createRevision()

        // WHEN
        post.deleteSyncedRevisions(until: revision2)

        // THEN
        XCTAssertEqual(post.revision, revision3)
        XCTAssertEqual(revision3.original, post)
        XCTAssertTrue(revision1.isDeleted)
        XCTAssertTrue(revision2.isDeleted)
        XCTAssertFalse(revision3.isDeleted)
    }

    func testDeleteRevisionDeletsAll() {
        // GIVEN a post with two revisions
        let post = PostBuilder(mainContext).build()
        let revision1 = post.createRevision()
        let revision2 = revision1.createRevision()

        // WHEN
        post.deleteAllRevisions()

        // THEN both revision got deleted
        XCTAssertNil(post.revision)
        XCTAssertTrue(revision1.isDeleted)
        XCTAssertTrue(revision2.isDeleted)
    }
}
