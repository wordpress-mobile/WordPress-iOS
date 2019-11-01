import UIKit
import XCTest
import Nimble

@testable import WordPress

private typealias StatusMessages = PostCardStatusViewModel.StatusMessages

class PostCardCellTests: XCTestCase {
    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    private var postCell: PostCardCell!
    private var interactivePostViewDelegateMock: InteractivePostViewDelegateMock!
    private var postActionSheetDelegateMock: PostActionSheetDelegateMock!

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()

        postCell = postCellFromNib()
        interactivePostViewDelegateMock = InteractivePostViewDelegateMock()
        postActionSheetDelegateMock = PostActionSheetDelegateMock()
        postCell.setInteractionDelegate(interactivePostViewDelegateMock)
        postCell.setActionSheetDelegate(postActionSheetDelegateMock)
    }

    override func tearDown() {
        context = nil
        contextManager = nil
        super.tearDown()
    }

    func testIsAUITableViewCell() {
        XCTAssertNotNil(postCell as UITableViewCell)
    }

    func testShowImageWhenAvailable() {
        let post = PostBuilder().withImage().build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.featuredImage.isHidden)
    }

    func testHideImageWhenNotAvailable() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.featuredImageStackView.isHidden)
    }

    func testShowPostTitle() {
        let post = PostBuilder().with(title: "Foo bar").build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.titleLabel.text, "Foo bar")
    }

    func testShowPostSnippet() {
        let post = PostBuilder().with(snippet: "Post content").build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.snippetLabel.text, "Post content")
        XCTAssertFalse(postCell.snippetLabel.isHidden)
    }

    func testHidePostSnippet() {
        let post = PostBuilder().with(snippet: "").build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.snippetLabel.isHidden)
    }

    func testShowDate() {
        let post = PostBuilder().with(dateModified: Date()).drafted().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.dateLabel.text, "just now")
    }

    func testShowAuthor() {
        let post = PostBuilder().with(author: "John Doe").build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.authorLabel.text, "John Doe")
    }

    func testShowStickyLabelWhenPostIsSticky() {
        let post = PostBuilder().is(sticked: true).with(remoteStatus: .sync).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel?.text, "Sticky")
    }

    func testHideStickyLabelWhenPostIsntSticky() {
        let post = PostBuilder().is(sticked: false).with(remoteStatus: .sync).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel?.text, "")
    }

    func testHideStickyLabelWhenPostIsUploading() {
        let post = PostBuilder().is(sticked: true).with(remoteStatus: .pushing).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel?.text, "Uploading post...")
    }

    func testHideStickyLabelWhenPostIsFailed() {
        let post = PostBuilder().is(sticked: true).with(remoteStatus: .failed).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel?.text, StatusMessages.uploadFailed)
    }

    func testShowPrivateLabelWhenPostIsPrivate() {
        let post = PostBuilder().with(remoteStatus: .sync).private().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel.text, "Private")
    }

    func testDoNotShowTrashedLabel() {
        let post = PostBuilder().with(remoteStatus: .sync).trashed().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel.text, "")
    }

    func testDoNotShowScheduledLabel() {
        let post = PostBuilder().with(remoteStatus: .sync).scheduled().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel.text, "")
    }

    func testHideHideStatusView() {
        let post = PostBuilder()
            .with(remoteStatus: .sync)
            .published().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.statusView.isHidden)
    }

    func testShowStatusView() {
        let post = PostBuilder()
            .with(remoteStatus: .failed)
            .published().build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.statusView.isHidden)
    }

    func testShowProgressView() {
        let post = PostBuilder()
            .with(remoteStatus: .pushing)
            .published().build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.progressView.isHidden)
    }

    func testHideProgressView() {
        let post = PostBuilder()
            .with(remoteStatus: .sync)
            .published().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.progressView.isHidden)
    }

    func testIsUserInteractionEnabled() {
        let post = PostBuilder().withImage().build()
        postCell.isUserInteractionEnabled = false

        postCell.configure(with: post)

        XCTAssertTrue(postCell.isUserInteractionEnabled)
    }

    func testEditAction() {
        let post = PostBuilder().published().build()
        postCell.configure(with: post)

        postCell.edit()

        XCTAssertTrue(interactivePostViewDelegateMock.didCallEdit)
    }

    func testViewAction() {
        let post = PostBuilder().published().build()
        postCell.configure(with: post)

        postCell.view()

        XCTAssertTrue(interactivePostViewDelegateMock.didCallView)
    }

    func testMoreAction() {
        let button = UIButton()
        let post = PostBuilder().published().build()
        postCell.configure(with: post)

        postCell.more(button)

        XCTAssertEqual(postActionSheetDelegateMock.calledWithPost, post)
        XCTAssertEqual(postActionSheetDelegateMock.calledWithView, button)
    }

    func testRetryAction() {
        let post = PostBuilder().published().build()
        postCell.configure(with: post)

        postCell.retry()

        XCTAssertTrue(interactivePostViewDelegateMock.didCallRetry)
    }

    func testShowPublishButtonAndHideViewButton() {
        let post = PostBuilder().private().with(remoteStatus: .failed).build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.publishButton.isHidden)
        XCTAssertTrue(postCell.viewButton.isHidden)
    }

    func testHideAuthorAndSeparator() {
        let post = PostBuilder().with(author: "John Doe").build()
        postCell.configure(with: post)

        postCell.isAuthorHidden = true

        XCTAssertTrue(postCell.authorLabel.isHidden)
        XCTAssertTrue(postCell.separatorLabel.isHidden)
    }

    func testDoesNotHideAuthorAndSeparator() {
        let post = PostBuilder().with(author: "John Doe").build()
        postCell.configure(with: post)

        postCell.isAuthorHidden = false

        XCTAssertFalse(postCell.authorLabel.isHidden)
        XCTAssertFalse(postCell.separatorLabel.isHidden)
    }

    func testShowsPostWillBePublishedWarningForFailedPublishedPostsWithRemote() {
        // Given
        let post = PostBuilder(context).published().withRemote().with(remoteStatus: .failed).confirmedAutoUpload().build()

        // When
        postCell.configure(with: post)

        // Then
        XCTAssertEqual(postCell.statusLabel.text, i18n("We'll publish the post when your device is back online."))
        XCTAssertEqual(postCell.statusLabel.textColor, UIColor.warning)
    }

    func testShowsPostWillBePublishedWarningForLocallyPublishedPosts() {
        // Given
        let post = PostBuilder(context).published().with(remoteStatus: .failed).confirmedAutoUpload().build()

        // When
        postCell.configure(with: post)

        // Then
        XCTAssertEqual(postCell.statusLabel.text, PostAutoUploadMessages.postWillBePublished)
        XCTAssertEqual(postCell.statusLabel.textColor, UIColor.warning)
    }

    func testShowsCancelButtonForUserConfirmedFailedPublishedPosts() {
        // Given
        let post = PostBuilder().published().with(remoteStatus: .failed).confirmedAutoUpload().build()

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
            PostBuilder(context).published().with(remoteStatus: .failed).build(),
            PostBuilder(context).drafted().with(remoteStatus: .failed).build()
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
        let post = PostBuilder()
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
        let post = PostBuilder(context).drafted().withRemote().with(remoteStatus: .failed).confirmedAutoUpload().build()

        // When
        postCell.configure(with: post)

        // Then
        XCTAssertEqual(postCell.statusLabel.text, i18n("We'll save your draft when your device is back online."))
        XCTAssertEqual(postCell.statusLabel.textColor, UIColor.warning)
    }

    func testShowsDraftWillBeUploadedMessageForLocalDrafts() {
        // Given
        let post = PostBuilder(context).drafted().with(remoteStatus: .failed).build()

        // When
        postCell.configure(with: post)

        // Then
        XCTAssertEqual(postCell.statusLabel.text, PostAutoUploadMessages.draftWillBeUploaded)
        XCTAssertEqual(postCell.statusLabel.textColor, UIColor.warning)
    }

    func testShowsFailedMessageWhenAttemptToAutoUploadADraft() {
        let post = PostBuilder(context).drafted().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 2).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't complete this action, but we'll try again later.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testFailedMessageWhenMaxNumberOfAttemptsToAutoDraftIsReached() {
        let post = PostBuilder(context).drafted().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 3).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't complete this action.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.error))
    }

    func testFailedMessageWhenMaxNumberOfAttemptsToAutoDraftIsReachedAndPostHasFailedMedia() {
        let post = PostBuilder(context).with(image: "", status: .failed).with(remoteStatus: .failed).with(autoUploadAttemptsCount: 3).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't upload this media, and didn't publish the post.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.error))
    }

    func testShowsFailedMessageWhenAttemptToAutoUploadAPrivatePost() {
        let post = PostBuilder(context).private().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 2).confirmedAutoUpload().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't publish this private post, but we'll try again later.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testFailedMessageWhenMaxNumberOfAttemptsToUploadPrivateIsReached() {
        let post = PostBuilder(context).private().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 3).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't complete this action, and didn't publish this private post.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.error))
    }

    func testShowsPrivatePostWillBeUploadedMessageForPrivatePosts() {
        let post = PostBuilder(context).private().with(remoteStatus: .failed).confirmedAutoUpload().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We'll publish your private post when your device is back online.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testShowsFailedMessageWhenAttemptToAutoUploadAScheduledPost() {
        let post = PostBuilder(context).scheduled().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 2).confirmedAutoUpload().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't schedule this post, but we'll try again later.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testFailedMessageWhenMaxNumberOfAttemptsToUploadScheduledIsReached() {
        let post = PostBuilder(context).scheduled().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 3).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't complete this action, and didn't schedule this post.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.error))
    }

    func testShowsScheduledPostWillBeUploadedMessageForScheduledPosts() {
        let post = PostBuilder(context).scheduled().with(remoteStatus: .failed).confirmedAutoUpload().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We'll schedule your post when your device is back online.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testShowsPostWillBeSubmittedMessageForPendingPost() {
        let post = PostBuilder(context).pending().with(remoteStatus: .failed).confirmedAutoUpload().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We'll submit your post for review when your device is back online.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testShowsFailedMessageWhenAttemptToSubmitAPendingPost() {
        let post = PostBuilder(context).pending().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 2).confirmedAutoUpload().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't submit this post for review, but we'll try again later.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
    }

    func testFailedMessageWhenMaxNumberOfAttemptsToSubmitPendingPostIsReached() {
        let post = PostBuilder(context).pending().with(remoteStatus: .failed).with(autoUploadAttemptsCount: 3).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't complete this action, and didn't submit this post for review.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.error))
    }

    func testFailedMessageForCanceledPostWithFailedMedias() {
        let post = PostBuilder(context).drafted().with(remoteStatus: .failed).with(image: "test.png", status: .failed, autoUploadFailureCount: 3).cancelledAutoUpload().revision().build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal(i18n("We couldn't upload this media.")))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.error))
    }

    func testMessageWhenPostIsArevision() {
        let post = PostBuilder(context).revision().with(remoteStatus: .failed).with(remoteStatus: .local).build()

        postCell.configure(with: post)

        expect(self.postCell.statusLabel.text).to(equal("Local changes"))
        expect(self.postCell.statusLabel.textColor).to(equal(UIColor.warning))
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
