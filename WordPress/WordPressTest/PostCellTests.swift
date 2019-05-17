import UIKit
import XCTest

@testable import WordPress

class PostCellTests: XCTestCase {

    var postCell: PostCell!
    var interactivePostViewDelegateMock: InteractivePostViewDelegateMock!
    var postActionSheetDelegateMock: PostActionSheetDelegateMock!

    override func setUp() {
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

        XCTAssertEqual(postCell.statusLabel?.text, "Upload failed")
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

    func testShowRetryButtonAndHideViewButton() {
        let post = PostBuilder().with(remoteStatus: .failed).build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.retryButton.isHidden)
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

    // GhostCellDelegate

    func testConfigureCellToBeDisplayedAsAGhost() {
        postCell.willStartGhostAnimation()

        XCTAssertTrue(postCell.featuredImage.isHidden)
        XCTAssertEqual(postCell.titleLabel?.text, " ")
        XCTAssertEqual(postCell.snippetLabel?.text, " ")
        XCTAssertFalse(postCell.snippetLabel.isHidden)
        XCTAssertEqual(postCell.dateLabel?.text, "dateGhostPlaceholder")
        XCTAssertTrue(postCell.authorLabel.isHidden)
        XCTAssertTrue(postCell.statusView.isHidden)
        XCTAssertTrue(postCell.progressView.isHidden)
        XCTAssertFalse(postCell.isUserInteractionEnabled)
        XCTAssertEqual(postCell.actionBarView.layer.opacity, 0.5)
    }

    private func postCellFromNib() -> PostCell {
        let bundle = Bundle(for: PostCell.self)
        guard let postCell = bundle.loadNibNamed("PostCell", owner: nil)?.first as? PostCell else {
            fatalError("PostCell does not exist")
        }

        return postCell
    }

}

class PostActionSheetDelegateMock: PostActionSheetDelegate {
    var calledWithPost: AbstractPost?
    var calledWithView: UIView?

    func showActionSheet(_ post: AbstractPost, from view: UIView) {
        calledWithPost = post
        calledWithView = view
    }
}
