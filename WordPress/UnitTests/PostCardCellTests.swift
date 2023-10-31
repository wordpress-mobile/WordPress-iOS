import UIKit
import XCTest
import Nimble

@testable import WordPress

private typealias StatusMessages = PostCardStatusViewModel.StatusMessages

class PostCardCellTests: CoreDataTestCase {
    private var postCell: PostCardCell!
    private var interactivePostViewDelegateMock: InteractivePostViewDelegateMock!
    private var postActionSheetDelegateMock: PostActionSheetDelegateMock!

    override func setUp() {
        super.setUp()

        postCell = postCellFromNib()
        interactivePostViewDelegateMock = InteractivePostViewDelegateMock()
        postActionSheetDelegateMock = PostActionSheetDelegateMock()
        postCell.setInteractionDelegate(interactivePostViewDelegateMock)
        postCell.setActionSheetDelegate(postActionSheetDelegateMock)
    }

    func testIsAUITableViewCell() {
        XCTAssertNotNil(postCell as UITableViewCell)
    }

    func testShowImageWhenAvailable() {
        let post = PostBuilder(mainContext).withImage().build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.featuredImage.isHidden)
    }

    func testHideImageWhenNotAvailable() {
        let post = PostBuilder(mainContext).build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.featuredImageStackView.isHidden)
    }

    func testShowPostTitle() {
        let post = PostBuilder(mainContext).with(title: "Foo bar").build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.titleLabel.text, "Foo bar")
    }

    func testShowPostSnippet() {
        let post = PostBuilder(mainContext).with(snippet: "Post content").build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.snippetLabel.text, "Post content")
        XCTAssertFalse(postCell.snippetLabel.isHidden)
    }

    func testHidePostSnippet() {
        let post = PostBuilder(mainContext).with(snippet: "").build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.snippetLabel.isHidden)
    }

    func testShowDate() {
        let post = PostBuilder(mainContext).with(dateModified: Date()).drafted().build()

        postCell.configure(with: post)

        expect(self.postCell.dateLabel.text).toNot(beEmpty())
    }

    func testShowAuthor() {
        let post = PostBuilder(mainContext).with(author: "John Doe").build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.authorLabel.text, "John Doe")
    }

    func testShowStickyLabelWhenPostIsSticky() {
        let post = PostBuilder(mainContext).is(sticked: true).with(remoteStatus: .sync).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel?.text, "Sticky")
    }

    func testHideStickyLabelWhenPostIsntSticky() {
        let post = PostBuilder(mainContext).is(sticked: false).with(remoteStatus: .sync).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel?.text, "")
    }

    func testHideStickyLabelWhenPostIsUploading() {
        let post = PostBuilder(mainContext).is(sticked: true).with(remoteStatus: .pushing).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel?.text, "Uploading post...")
    }

    func testHideStickyLabelWhenPostIsFailed() {
        let post = PostBuilder(mainContext).is(sticked: true).with(remoteStatus: .failed).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel?.text, StatusMessages.uploadFailed)
    }

    func testShowPrivateLabelWhenPostIsPrivate() {
        let post = PostBuilder(mainContext).with(remoteStatus: .sync).private().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel.text, "Private")
    }

    func testDoNotShowTrashedLabel() {
        let post = PostBuilder(mainContext).with(remoteStatus: .sync).trashed().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel.text, "")
    }

    func testDoNotShowScheduledLabel() {
        let post = PostBuilder(mainContext).with(remoteStatus: .sync).scheduled().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel.text, "")
    }

    func testHideHideStatusView() {
        let post = PostBuilder(mainContext)
            .with(remoteStatus: .sync)
            .published().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.statusView.isHidden)
    }

    func testShowStatusView() {
        let post = PostBuilder(mainContext)
            .with(remoteStatus: .failed)
            .published().build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.statusView.isHidden)
    }

    func testShowProgressView() {
        let post = PostBuilder(mainContext)
            .with(remoteStatus: .pushing)
            .published().build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.progressView.isHidden)
    }

    func testHideProgressView() {
        let post = PostBuilder(mainContext)
            .with(remoteStatus: .sync)
            .published().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.progressView.isHidden)
    }

    func testIsUserInteractionEnabled() {
        let post = PostBuilder(mainContext).withImage().build()
        postCell.isUserInteractionEnabled = false

        postCell.configure(with: post)

        XCTAssertTrue(postCell.isUserInteractionEnabled)
    }

    func testEditAction() {
        let post = PostBuilder(mainContext).published().build()
        postCell.configure(with: post)

        postCell.edit()

        XCTAssertTrue(interactivePostViewDelegateMock.didCallEdit)
    }

    func testViewAction() {
        let post = PostBuilder(mainContext).published().build()
        postCell.configure(with: post)

        postCell.view()

        XCTAssertTrue(interactivePostViewDelegateMock.didCallView)
    }

    func testMoreAction() {
        let button = UIButton()
        let post = PostBuilder(mainContext).published().build()
        postCell.configure(with: post)

        postCell.more(button)

        XCTAssertEqual(postActionSheetDelegateMock.calledWithPost, post)
        XCTAssertEqual(postActionSheetDelegateMock.calledWithView, button)
    }

    func testRetryAction() {
        let post = PostBuilder(mainContext).published().build()
        postCell.configure(with: post)

        postCell.retry()

        XCTAssertTrue(interactivePostViewDelegateMock.didCallRetry)
    }

    func testShowPublishButtonAndHideViewButton() {
        let post = PostBuilder(mainContext).private().with(remoteStatus: .failed).build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.publishButton.isHidden)
        XCTAssertTrue(postCell.viewButton.isHidden)
    }

    func testHideAuthorAndSeparator() {
        let post = PostBuilder(mainContext).with(author: "John Doe").build()
        postCell.configure(with: post)

        postCell.shouldHideAuthor = true

        XCTAssertTrue(postCell.authorLabel.isHidden)
        XCTAssertTrue(postCell.separatorLabel.isHidden)
    }

    func testDoesNotHideAuthorAndSeparator() {
        let post = PostBuilder(mainContext).with(author: "John Doe").build()
        postCell.configure(with: post)

        postCell.shouldHideAuthor = false

        XCTAssertFalse(postCell.authorLabel.isHidden)
        XCTAssertFalse(postCell.separatorLabel.isHidden)
    }

    func testHidesAuthorSeparatorWhenAuthorEmpty() {
        let post = PostBuilder(mainContext).with(author: "").build()
        postCell.configure(with: post)

        postCell.shouldHideAuthor = false

        XCTAssertTrue(postCell.authorLabel.isHidden)
        XCTAssertTrue(postCell.separatorLabel.isHidden)
    }

    func testShowsPostWillBePublishedWarningForFailedPublishedPostsWithRemote() {
        // Given
        let post = PostBuilder(mainContext).published().withRemote().with(remoteStatus: .failed).confirmedAutoUpload().build()

        // When
        postCell.configure(with: post)

        // Then
        XCTAssertEqual(postCell.statusLabel.text, i18n("We'll publish the post when your device is back online."))
        XCTAssertEqual(postCell.statusLabel.textColor, UIColor.warning)
    }

    func testShowsPostWillBePublishedWarningForLocallyPublishedPosts() {
        // Given
        let post = PostBuilder(mainContext).published().with(remoteStatus: .failed).confirmedAutoUpload().build()

        // When
        postCell.configure(with: post)

        // Then
        XCTAssertEqual(postCell.statusLabel.text, i18n("We'll publish the post when your device is back online."))
        XCTAssertEqual(postCell.statusLabel.textColor, UIColor.warning)
    }

    func testShowsCancelButtonForUserConfirmedFailedPublishedPosts() {
        // Given
        let post = PostBuilder(mainContext).published().with(remoteStatus: .failed).confirmedAutoUpload().build()

        // When
        postCell.configure(with: post)

        // Then
        XCTAssertTrue(postCell.retryButton.isHidden)
        XCTAssertFalse(postCell.cancelAutoUploadButton.isHidden)
    }

    /// TODO We will be showing "Publish" buttons like on Android instead.
    func testDoesNotShowRetryButtonForUnconfirmedFailedLocalDraftsAndPublishedPosts() {
        // A post can be unconfirmed if:
        //
        // - The user pressed the Published button (confirmed) but pressed Cancel in the Post List.
        // - The user edited a published post but the editor crashed.

        // Arrange
        let posts = [
            PostBuilder(mainContext).published().with(remoteStatus: .failed).build(),
            PostBuilder(mainContext).drafted().with(remoteStatus: .failed).build()
        ]

        // Act and Assert
        for post in posts {
            postCell.configure(with: post)

            XCTAssertTrue(postCell.retryButton.isHidden)
            XCTAssertTrue(postCell.cancelAutoUploadButton.isHidden)
        }
    }

    func testDoesntShowFailedForCancelledAutoUploads() {
        // Given
        let post = PostBuilder(mainContext)
            .published()
            .with(remoteStatus: .failed)
            .confirmedAutoUpload()
            .cancelledAutoUpload()
            .build()

        // When
        postCell.configure(with: post)

        // Then
        XCTAssertEqual(postCell.statusLabel.text, StatusMessages.localChanges)
        XCTAssertEqual(postCell.statusLabel.textColor, UIColor.warning)
    }

    func testShowsDraftWillBeUploadedMessageForDraftsWithRemote() {
        // Given
        let post = PostBuilder(mainContext).drafted().withRemote().with(remoteStatus: .failed).confirmedAutoUpload().build()

        // When
        postCell.configure(with: post)

        // Then
        XCTAssertEqual(postCell.statusLabel.text, i18n("We'll save your draft when your device is back online."))
        XCTAssertEqual(postCell.statusLabel.textColor, UIColor.warning)
    }

    func testShowsDraftWillBeUploadedMessageForLocalDrafts() {
        // Given
        let post = PostBuilder(mainContext).drafted().with(remoteStatus: .failed).build()

        // When
        postCell.configure(with: post)

        // Then
        XCTAssertEqual(postCell.statusLabel.text, i18n("We'll save your draft when your device is back online."))
        XCTAssertEqual(postCell.statusLabel.textColor, UIColor.warning)
    }

    func testShowsFailedMessageWhenAttemptToAutoUploadADraft() {
        let post = PostBuilder(mainContext).drafted().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 2).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't complete this action, but we'll try again later.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testFailedMessageWhenMaxNumberOfAttemptsToAutoDraftIsReached() {
        let post = PostBuilder(mainContext).drafted().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 3).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't complete this action.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.error))
    }

    func testFailedMessageWhenMaxNumberOfAttemptsToAutoDraftIsReachedAndPostHasFailedMedia() {
        let post = PostBuilder(mainContext).with(image: "", status: .failed).with(remoteStatus: .failed).with(autoUploadAttemptsCount: 3).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't upload this media, and didn't publish the post.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.error))
    }

    func testShowsFailedMessageWhenAttemptToAutoUploadAPrivatePost() {
        let post = PostBuilder(mainContext).private().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 2).confirmedAutoUpload().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't publish this private post, but we'll try again later.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testFailedMessageWhenMaxNumberOfAttemptsToUploadPrivateIsReached() {
        let post = PostBuilder(mainContext).private().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 3).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't complete this action, and didn't publish this private post.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.error))
    }

    func testShowsPrivatePostWillBeUploadedMessageForPrivatePosts() {
        let post = PostBuilder(mainContext).private().with(remoteStatus: .failed).confirmedAutoUpload().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We'll publish your private post when your device is back online.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testShowsFailedMessageWhenAttemptToAutoUploadAScheduledPost() {
        let post = PostBuilder(mainContext).scheduled().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 2).confirmedAutoUpload().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't schedule this post, but we'll try again later.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testFailedMessageWhenMaxNumberOfAttemptsToUploadScheduledIsReached() {
        let post = PostBuilder(mainContext).scheduled().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 3).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't complete this action, and didn't schedule this post.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.error))
    }

    func testShowsScheduledPostWillBeUploadedMessageForScheduledPosts() {
        let post = PostBuilder(mainContext).scheduled().with(remoteStatus: .failed).confirmedAutoUpload().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We'll schedule your post when your device is back online.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testShowsPostWillBeSubmittedMessageForPendingPost() {
        let post = PostBuilder(mainContext).pending().with(remoteStatus: .failed).confirmedAutoUpload().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We'll submit your post for review when your device is back online.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testShowsFailedMessageWhenAttemptToSubmitAPendingPost() {
        let post = PostBuilder(mainContext).pending().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 2).confirmedAutoUpload().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't submit this post for review, but we'll try again later.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testFailedMessageWhenMaxNumberOfAttemptsToSubmitPendingPostIsReached() {
        let post = PostBuilder(mainContext).pending().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 3).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't complete this action, and didn't submit this post for review.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.error))
    }

    func testFailedMessageForCanceledPostWithFailedMedias() {
        let post = PostBuilder(mainContext).drafted().with(remoteStatus: .failed).with(image: "test.png", status: .failed, autoUploadFailureCount: 3).cancelledAutoUpload().revision().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't upload this media.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.error))
    }

    func testMessageWhenPostIsArevision() {
        let post = PostBuilder(mainContext).revision().with(remoteStatus: .failed).with(remoteStatus: .local).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal("Local changes"))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testShowsUnsavedChangesMessageWhenPostHasAutosave() {
        let post = PostBuilder(mainContext).with(remoteStatus: .sync).autosaved().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("You've made unsaved changes to this post")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning(.shade40)))
    }

    private func postCellFromNib() -> PostCardCell {
        let bundle = Bundle(for: PostCardCell.self)
        guard let postCell = bundle.loadNibNamed("PostCardCell", owner: nil)?.first as? PostCardCell else {
            fatalError("PostCardCell does not exist")
        }

        return postCell
    }

}

class PostActionSheetDelegateMock: PostActionSheetDelegate {
    var calledWithPost: AbstractPost?
    var calledWithView: UIView?

    func showActionSheet(_ postCardStatusViewModel: PostCardStatusViewModel, from view: UIView) {
        calledWithPost = postCardStatusViewModel.post
        calledWithView = view
    }
}
