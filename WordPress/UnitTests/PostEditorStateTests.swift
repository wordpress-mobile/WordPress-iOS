import XCTest
@testable import WordPress

class PostEditorStateTests: XCTestCase {
    var context: PostEditorStateContext!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()

        context = nil
    }

    func testContextNoContentPublishButtonDisabled() {
        context = PostEditorStateContext(originalPostStatus: .publish, userCanPublish: true, delegate: self)

        context.updated(hasContent: false)

        XCTAssertFalse(context.isPublishButtonEnabled)
    }

    func testContextChangedNewPostToDraft() {
        context = PostEditorStateContext(originalPostStatus: nil, userCanPublish: true, delegate: self)

        context.updated(postStatus: .draft)

        XCTAssertEqual(PostEditorAction.publish, context.action, "New posts, even if switched to draft, should show Publish button.")
    }

    func testContextExistingDraft() {
        context = PostEditorStateContext(originalPostStatus: .draft, userCanPublish: true, delegate: self)

        XCTAssertEqual(PostEditorAction.update, context.action, "Existing draft posts should show Update button.")
    }

    func testContextScheduledPost() {
        context = PostEditorStateContext(originalPostStatus: .scheduled, userCanPublish: true, delegate: self)

        XCTAssertEqual(PostEditorAction.update, context.action, "Scheduled posts should show Update")
    }

    func testContextScheduledPostUpdated() {
        context = PostEditorStateContext(originalPostStatus: .scheduled, userCanPublish: true, delegate: self)

        context.updated(postStatus: .scheduled)

        XCTAssertEqual(PostEditorAction.update, context.action, "Scheduled posts that get updated should still show Update")
    }
}

// These tests are all based off of Calypso unit tests
// https://github.com/Automattic/wp-calypso/blob/master/client/post-editor/editor-publish-button/test/index.jsx
extension PostEditorStateTests {
    func testContextChangedPublishedPostStaysPublished() {
        context = PostEditorStateContext(originalPostStatus: .publish, userCanPublish: true, delegate: self)

        XCTAssertEqual(PostEditorAction.update, context.action, "should return Update if the post was originally published and is still slated to be published")
    }

    func testContextChangedPublishedPostToDraft() {
        context = PostEditorStateContext(originalPostStatus: .publish, userCanPublish: true, delegate: self)

        context.updated(postStatus: .draft)

        XCTAssertEqual(PostEditorAction.update, context.action, "should return Update if the post was originally published and is currently reverted to non-published status")
    }

    func testContextPostFutureDatedAlreadyScheduled() {
        context = PostEditorStateContext(originalPostStatus: .scheduled, userCanPublish: true, delegate: self)

        context.updated(postStatus: .scheduled)
        context.updated(publishDate: Date.distantFuture)

        XCTAssertEqual(PostEditorAction.update, context.action, "should return Update if the post is scheduled and dated in the future")
    }

    func testContextUpdatingAlreadyScheduledToDraft() {
        context = PostEditorStateContext(originalPostStatus: .scheduled, userCanPublish: true, delegate: self)

        context.updated(publishDate: Date.distantFuture)
        context.updated(postStatus: .draft)

        XCTAssertEqual(PostEditorAction.update, context.action, "should return Update if the post is scheduled, dated in the future, and next status is draft")
    }

    func testContextDraftPost() {
        context = PostEditorStateContext(originalPostStatus: nil, userCanPublish: true, delegate: self)

        XCTAssertEqual(PostEditorAction.publish, context.action, "should return Publish if the post is a draft")
    }

    func testContextUserCannotPublish() {
        context = PostEditorStateContext(originalPostStatus: nil, userCanPublish: false, delegate: self)

        XCTAssertEqual(PostEditorAction.submitForReview, context.action, "should return 'Submit for Review' if the post is a draft and user can't publish")
    }

    func testPublishEnabledHasContentAndChangesNotPublishing() {
        context = PostEditorStateContext(originalPostStatus: .draft, userCanPublish: true, delegate: self)
        context.updated(hasContent: true)
        context.updated(hasChanges: true)
        context.updated(isBeingPublished: false)

        XCTAssertTrue(context.isPublishButtonEnabled, "should return true if form is not publishing and post is not empty")
    }

    func testPublishDisabledHasContentAndNoChangesNotPublishing() {
        context = PostEditorStateContext(originalPostStatus: .draft, userCanPublish: true, delegate: self)
        context.updated(hasContent: true)
        context.updated(hasChanges: false)
        context.updated(isBeingPublished: false)

        XCTAssertFalse(context.isPublishButtonEnabled, "should return true if form is not publishing and post is not empty")
    }

    // Missing test: should return false if form is not publishing and post is not empty, but user is not verified

    // Missing test: should return true if form is not published and post is new and has content, but is not dirty

    func testPublishDisabledDuringPublishing() {
        context = PostEditorStateContext(originalPostStatus: .draft, userCanPublish: true, delegate: self)
        context.updated(isBeingPublished: true)

        XCTAssertFalse(context.isPublishButtonEnabled, "should return false if form is publishing")
    }

    // Missing test: should return false if saving is blocked

    // Missing test: should return false if not dirty and has no content

    func testPublishDisabledNoContent() {
        context = PostEditorStateContext(originalPostStatus: .draft, userCanPublish: true, delegate: self)
        context.updated(hasContent: false)

        XCTAssertFalse(context.isPublishButtonEnabled, "should return false if post has no content")
    }
}

extension PostEditorStateTests {
    func testPublishSecondaryDisabledNoContent() {
        context = PostEditorStateContext(originalPostStatus: nil, userCanPublish: true, delegate: self)
        context.updated(hasContent: false)

        XCTAssertFalse(context.isSecondaryPublishButtonShown, "should return false if post has no content")
    }

    func testPublishSecondaryAlreadyPublishedPosts() {
        context = PostEditorStateContext(originalPostStatus: .publish, userCanPublish: true, delegate: self)
        context.updated(hasContent: true)

        XCTAssertEqual(PostEditorAction.update, context.action)
        XCTAssertFalse(context.isSecondaryPublishButtonShown, "should return false for already published posts")
    }

    func testPublishSecondaryAlreadyDraftedPosts() {
        context = PostEditorStateContext(originalPostStatus: .draft, userCanPublish: true, delegate: self)
        context.updated(hasContent: true)

        XCTAssertTrue(context.isSecondaryPublishButtonShown, "should return true for existing drafts (publish now)")
    }

    func testPublishSecondaryExistingFutureDatedDrafts() {
        context = PostEditorStateContext(originalPostStatus: .draft, userCanPublish: true, publishDate: Date.distantFuture, delegate: self)
        context.updated(hasContent: true)

        XCTAssertFalse(context.isSecondaryPublishButtonShown, "should return false for existing future-dated drafts (no publish now)")
    }

    func testPublishSecondaryAlreadyScheduledPosts() {
        context = PostEditorStateContext(originalPostStatus: .scheduled, userCanPublish: true, publishDate: Date.distantFuture, delegate: self)
        context.updated(hasContent: true)

        XCTAssertFalse(context.isSecondaryPublishButtonShown, "should return false for existing scheduled drafts (no publish now)")
    }
}

extension PostEditorStateTests: PostEditorStateContextDelegate {
    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction) {

    }

    func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool) {

    }
}
