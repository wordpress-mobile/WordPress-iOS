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
        context = PostEditorStateContext(originalPostStatus: .draft, userCanPublish: true, delegate: self)

        context.updated(postStatus: .draft)

        XCTAssertEqual(PostEditorAction.save, context.action, "New posts switched to draft should show Save button.")
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

    func testContextPostFutureDatedButNotYetScheduled() {
        context = PostEditorStateContext(originalPostStatus: .draft, userCanPublish: true, delegate: self)

        context.updated(postStatus: .publish)
        context.updated(publishDate: Date.distantFuture)

        XCTAssertEqual(PostEditorAction.schedule, context.action, "should return Schedule if the post is dated in the future and not scheduled")
    }

    func testContextPostFutureDatedAlreadyPublished() {
        context = PostEditorStateContext(originalPostStatus: .publish, userCanPublish: true, delegate: self)

        context.updated(postStatus: .publish)
        context.updated(publishDate: Date.distantFuture)

        XCTAssertEqual(PostEditorAction.schedule, context.action, "should return Schedule if the post is dated in the future and published")
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

    func testContextPostPastDatedAlreadyScheduled() {
        context = PostEditorStateContext(originalPostStatus: .scheduled, userCanPublish: true, delegate: self)

        context.updated(publishDate: Date.distantPast)
        context.updated(postStatus: .scheduled)

        XCTAssertEqual(PostEditorAction.publish, context.action, "should return Publish if the post is scheduled and dated in the past")
    }

    func testContextDraftPost() {
        context = PostEditorStateContext(originalPostStatus: .draft, userCanPublish: true, delegate: self)

        XCTAssertEqual(PostEditorAction.publish, context.action, "should return Publish if the post is a draft")
    }

    func testContextUserCannotPublish() {
        context = PostEditorStateContext(originalPostStatus: .draft, userCanPublish: false, delegate: self)

        XCTAssertEqual(PostEditorAction.submitForReview, context.action, "should return 'Submit for Review' if the post is a draft and user can't publish")
    }
}

extension PostEditorStateTests: PostEditorStateContextDelegate {
    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction) {

    }
}
